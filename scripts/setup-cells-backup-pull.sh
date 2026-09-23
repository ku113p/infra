#!/usr/bin/env bash
# One-time per cell on the VPS: the pull of its nightly backup (decision 0037 in the private
# repo ku113p/cells) — a system user that can write one directory and nothing else, the
# settings, the hourly timer, and the packages the old drop box already holds. Copy the pull
# script first, then run this:
#
#   scp scripts/cells-backup-pull.sh root@$VPS_HOST:/usr/local/sbin/
#   ssh root@$VPS_HOST 'bash -s -- emp-a http://10.99.0.2:8080' < scripts/setup-cells-backup-pull.sh
#
# The cell's backup token is not handled here: it goes from the cell to
# /etc/cells-backup/<cell>.header in one pipe, never printed: docs/runbooks/backup-pull.md in
# the cells repo, step 2.
# The Kuma push URL is read from Kuma's own database (the monitor `cells: backup <cell>`,
# scripts/setup-cells-monitors.sh). Re-running is safe.
set -euo pipefail
cell="${1:?usage: setup-cells-backup-pull.sh <cell> <cell-url>}"
url="${2:?usage: setup-cells-backup-pull.sh <cell> <cell-url>}"
user=cellspull
root=/opt/services/backup/pulled
test -f /usr/local/sbin/cells-backup-pull.sh && chmod 755 /usr/local/sbin/cells-backup-pull.sh

id "$user" >/dev/null 2>&1 || useradd --system --shell /usr/sbin/nologin --no-create-home "$user"
install -d -m 755 -o root -g root "$root"
install -d -m 750 -o "$user" -g "$user" "$root/$cell"
install -d -m 750 -o root -g "$user" /etc/cells-backup

token=$(docker run --rm -v monitoring_kuma-data:/app/data --entrypoint sqlite3 louislam/uptime-kuma:1 \
  /app/data/kuma.db "select push_token from monitor where name = 'cells: backup $cell'")
[ -n "$token" ] || { echo "no Kuma monitor 'cells: backup $cell': run setup-cells-monitors.sh" >&2; exit 1; }
umask 027
printf 'CELL_URL=%s\nKUMA_PUSH_URL=%s\n' "$url" "https://monitor.syncapp.tech/api/push/$token" \
  > "/etc/cells-backup/$cell.env"
chgrp "$user" "/etc/cells-backup/$cell.env"

cat > /etc/systemd/system/cells-backup-pull@.service <<'UNIT'
[Unit]
Description=Pull the nightly backup of cell %i (cells decision 0037)
After=network-online.target wg-quick@wg0.service
Wants=network-online.target

[Service]
Type=oneshot
User=cellspull
Group=cellspull
ExecStart=/usr/local/sbin/cells-backup-pull.sh %i
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/services/backup/pulled/%i
UNIT
cat > /etc/systemd/system/cells-backup-pull@.timer <<'UNIT'
[Unit]
Description=Hourly pull of the nightly backup of cell %i

[Timer]
OnCalendar=hourly
RandomizedDelaySec=10m
Persistent=true

[Install]
WantedBy=timers.target
UNIT
systemctl daemon-reload

# What the old drop box holds comes along, so the history does not start today.
old=/opt/services/backup/$cell
if [ -d "$old" ]; then
  for f in "$old"/*.tar.gz.age "$old"/*.tar.gz.age.sha256; do
    [ -e "$f" ] && [ ! -e "$root/$cell/$(basename "$f")" ] && install -m 640 -o "$user" -g "$user" "$f" "$root/$cell/"
  done
fi

if [ -s "/etc/cells-backup/$cell.header" ]; then
  chgrp "$user" "/etc/cells-backup/$cell.header"; chmod 640 "/etc/cells-backup/$cell.header"
  systemctl enable --now "cells-backup-pull@$cell.timer"
  echo "timer on: $(systemctl list-timers "cells-backup-pull@$cell.timer" --no-legend | head -1)"
else
  echo "no /etc/cells-backup/$cell.header yet: put the token there, then run this again" >&2
fi
ls -l "$root/$cell"
