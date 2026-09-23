#!/usr/bin/env bash
# Uptime Kuma's monitors for the agent cells (decisions 0024 and 0033 in the private repo
# ku113p/cells). Kuma has no API for its own configuration, so this writes its sqlite directly,
# with the container stopped (WAL, and Kuma reads monitors only at start) and a copy kept
# beside it. sqlite3 comes from Kuma's own image. Rows are matched by name: a monitor that
# exists is left as it is, so a threshold changed in the UI survives a re-run.
#
#   ssh root@$VPS_HOST 'bash -s' < scripts/setup-cells-monitors.sh
#
# The Telegram channel (the hub's bot into the operator's chat) is created only when it is
# missing, and only then are its two values needed:
#
#   ssh root@$VPS_HOST "KUMA_TG_BOT=... KUMA_TG_CHAT=... bash -s" < scripts/setup-cells-monitors.sh
set -euo pipefail
VOL=monitoring_kuma-data
HUB_URL=https://hub.syncapp.tech/healthz
CELL_URL=http://10.99.0.2:8080/health   # emp-a through the WireGuard tunnel

kuma_sqlite() { docker run --rm -i -v "$VOL":/app/data --entrypoint sqlite3 louislam/uptime-kuma:1 /app/data/kuma.db "$@"; }

DIR=$(docker volume inspect "$VOL" -f '{{.Mountpoint}}')
test -f "$DIR/kuma.db"
if [ "$(kuma_sqlite "select count(*) from notification where name = 'telegram'")" = 0 ]; then
  : "${KUMA_TG_BOT:?no telegram channel yet: pass KUMA_TG_BOT and KUMA_TG_CHAT}"
  : "${KUMA_TG_CHAT:?no telegram channel yet: pass KUMA_TG_BOT and KUMA_TG_CHAT}"
fi

docker stop uptime-kuma >/dev/null
trap 'docker start uptime-kuma >/dev/null' EXIT
stamp=$(date +%Y%m%d-%H%M%S)
for f in kuma.db kuma.db-wal kuma.db-shm; do
  [ -e "$DIR/$f" ] && cp -a "$DIR/$f" "$DIR/$f.bak-$stamp"
done
echo "backup: $DIR/kuma.db.bak-$stamp"

push_token=$(head -c 40 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 20)

kuma_sqlite <<SQL
PRAGMA foreign_keys = ON;
BEGIN;

INSERT INTO notification (name, active, user_id, is_default, config)
SELECT 'telegram', 1, 1, 1, json_object(
    'name', 'telegram', 'type', 'telegram', 'isDefault', 1, 'applyExisting', 0,
    'telegramBotToken', '${KUMA_TG_BOT:-}', 'telegramChatID', '${KUMA_TG_CHAT:-}',
    'telegramSendSilently', 0, 'telegramProtectContent', 0)
WHERE NOT EXISTS (SELECT 1 FROM notification WHERE name = 'telegram');

-- The hub is up.
INSERT INTO monitor (name, active, user_id, interval, retry_interval, maxretries, resend_interval,
                     url, type, weight, accepted_statuscodes_json, timeout, json_path, expected_value,
                     method, maxredirects, expiry_notification, upside_down, ignore_tls)
SELECT 'cells: hub', 1, 1, 60, 60, 3, 0,
       '${HUB_URL}', 'json-query', 2000, '["200-299"]', 20.0, '\$.ok', 'true',
       'GET', 10, 1, 0, 0
WHERE NOT EXISTS (SELECT 1 FROM monitor WHERE name = 'cells: hub');

-- The cell and the hub run the same code (decision 0033). The hub writes JSON without spaces,
-- so the exact text is the keyword; a cell the hub never reached is "match":null and stays up.
-- One deploy is hub first, then the cell, a few minutes apart: five retries a minute apart
-- sit through that and still page for a deploy made around the script.
INSERT INTO monitor (name, active, user_id, interval, retry_interval, maxretries, resend_interval,
                     url, type, weight, accepted_statuscodes_json, timeout, keyword, invert_keyword,
                     method, maxredirects, expiry_notification, upside_down, ignore_tls)
SELECT 'cells: versions', 1, 1, 60, 60, 5, 0,
       '${HUB_URL}', 'keyword', 2000, '["200-299"]', 20.0, '"match":false', 1,
       'GET', 10, 0, 0, 0
WHERE NOT EXISTS (SELECT 1 FROM monitor WHERE name = 'cells: versions');

-- The cell, through the tunnel. Ten retries a minute apart: the tunnel heals itself after
-- three of them and a closed laptop should not page anyone.
INSERT INTO monitor (name, active, user_id, interval, retry_interval, maxretries, resend_interval,
                     url, type, weight, accepted_statuscodes_json, timeout, json_path, expected_value,
                     method, maxredirects, expiry_notification, upside_down, ignore_tls)
SELECT 'cells: emp-a', 1, 1, 60, 60, 10, 0,
       '${CELL_URL}', 'json-query', 2000, '["200-299"]', 20.0, '\$.status', 'ok',
       'GET', 10, 0, 0, 0
WHERE NOT EXISTS (SELECT 1 FROM monitor WHERE name = 'cells: emp-a');

-- The nightly backup pings this once it has verified a fresh package on the VPS; 36 h of
-- silence is a failed backup (the laptop may sleep through one window).
INSERT INTO monitor (name, active, user_id, interval, retry_interval, maxretries, resend_interval,
                     type, weight, push_token, accepted_statuscodes_json, timeout,
                     method, maxredirects, expiry_notification, upside_down, ignore_tls)
SELECT 'cells: backup emp-a', 1, 1, 129600, 3600, 0, 0,
       'push', 2000, '${push_token}', '["200-299"]', 20.0,
       'GET', 10, 0, 0, 0
WHERE NOT EXISTS (SELECT 1 FROM monitor WHERE name = 'cells: backup emp-a');

-- Every one of them notifies.
INSERT INTO monitor_notification (id, monitor_id, notification_id)
SELECT (SELECT COALESCE(MAX(id), 0) FROM monitor_notification) + ROW_NUMBER() OVER (ORDER BY m.id),
       m.id, n.id
FROM monitor m, notification n
WHERE m.name LIKE 'cells: %' AND n.name = 'telegram'
  AND NOT EXISTS (SELECT 1 FROM monitor_notification mn
                  WHERE mn.monitor_id = m.id AND mn.notification_id = n.id);

COMMIT;
SQL

docker start uptime-kuma >/dev/null
trap - EXIT
kuma_sqlite "select m.id, m.name, m.type, m.interval, m.maxretries,
                    coalesce(m.json_path, m.keyword, ''), coalesce(m.expected_value, ''),
                    (select count(*) from monitor_notification mn where mn.monitor_id = m.id)
             from monitor m where m.name like 'cells: %' order by m.id"
echo "backup push url: https://monitor.syncapp.tech/api/push/$(kuma_sqlite "select push_token from monitor where name = 'cells: backup emp-a'")"
