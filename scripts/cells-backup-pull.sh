#!/usr/bin/env bash
# The VPS takes the agent cells' nightly backup (decision 0037 in the private repo
# ku113p/cells). The laptop used to carry it here and ping the watcher; three days of
# silence in a row were a sleeping laptop and a stuck VM manager, not a failed backup. Now
# this host asks the cell's API over the WireGuard tunnel for the newest package, checks it
# and says so to Uptime Kuma itself.
#
#   cells-backup-pull.sh <cell>      run by cells-backup-pull@<cell>.timer, hourly
#
# /etc/cells-backup/<cell>.env holds CELL_URL (http://10.99.0.2:8080) and KUMA_PUSH_URL;
# /etc/cells-backup/<cell>.header is the one header line with the cell's backup token — a
# token that opens the package list and the packages and nothing else of the cell. The
# packages are age-encrypted to a key this host does not have, and the cell cannot write
# here: it only serves. It is still not trusted: a cell that turned hostile could serve a
# new, well-formed package every hour and fill this disk while the monitor stayed green
# (found by two refuters, 2026-09-23). So a package is taken only if its stamp is six hours
# after the newest one here and not in the future, it has a size cap, the directory has one
# too, and the newest of each month is kept for a year whatever came after it.
set -euo pipefail
cell="${1:?usage: cells-backup-pull.sh <cell>}"
conf="/etc/cells-backup/$cell.env"
header="/etc/cells-backup/$cell.header"
dir="/opt/services/backup/pulled/$cell"
keep_days=30
keep_min=7
max_bytes=$((256 * 1024 * 1024))        # a package; they are ~10 MB today
max_dir_bytes=$((5 * 1024 * 1024 * 1024))
min_gap_h=6                              # a hostile cell adds at most four a day; the directory cap pages
# shellcheck source=/dev/null
. "$conf"
: "${CELL_URL:?CELL_URL missing in $conf}" "${KUMA_PUSH_URL:?KUMA_PUSH_URL missing in $conf}"

push() {  # status, message — to the push monitor `cells: backup <cell>`
  curl -fsS --max-time 20 -G "$KUMA_PUSH_URL" --data-urlencode "status=$1" \
    --data-urlencode "msg=$2" >/dev/null || true
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
# A network error says nothing yet: a closed laptop lid pauses the cell, the next hour
# tries again, and the monitor's 36 hours of silence is what pages. An answer that is not
# 200 is another thing — a token the two sides no longer share (401), the endpoints
# switched off (404), the cell failing (5xx) — and no hour will fix it: that pages now.
status="$(curl -sS --max-time 30 -H @"$header" -o "$tmp" -w '%{http_code}' "$CELL_URL/backups")" || {
  echo "the cell did not answer: nothing pulled this hour" >&2
  exit 0
}
if [ "$status" != 200 ]; then
  case "$status" in
    401|404) why="the cell refused the backup list ($status): the token on both sides?" ;;
    *) why="the cell failed to list its backups ($status)" ;;
  esac
  echo "$why" >&2
  push down "$why"
  exit 1
fi

used="$(du -sb "$dir" | awk '{print $1}')"
if [ "$used" -ge "$max_dir_bytes" ]; then
  echo "$dir holds $used bytes, over $max_dir_bytes: nothing more is taken" >&2
  push down "backup directory over its cap ($used bytes)"
  exit 1
fi

# The newest package, if it is one to take: a name of this cell's shape, a sum listed, a
# size under the cap, a stamp six hours after the newest here and not in the future.
read -r name want size < <(python3 - "$dir" "$tmp" "$cell" "$max_bytes" "$min_gap_h" <<'PY'
import datetime as dt, json, os, re, sys
d, path, cell, cap, gap = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), int(sys.argv[5])
shape = re.compile(re.escape(cell) + r"-([0-9]{8}-[0-9]{4})\.tar\.gz\.age")
def stamp(n):
    m = shape.fullmatch(n)
    return dt.datetime.strptime(m.group(1), "%Y%m%d-%H%M").replace(tzinfo=dt.UTC) if m else None
held = [s for s in (stamp(n) for n in os.listdir(d)) if s]
newest = max(held, default=None)
now = dt.datetime.now(dt.UTC)
for item in json.load(open(path)):  # the cell lists newest first
    n, s = str(item.get("name", "")), stamp(str(item.get("name", "")))
    if s is None or not item.get("sha256"):
        continue  # not a package of this cell, or its sum is not written yet
    fresh = s <= now + dt.timedelta(hours=1) and (
        newest is None or s >= newest + dt.timedelta(hours=gap))
    if fresh and int(item.get("bytes") or 0) <= cap and not os.path.exists(os.path.join(d, n)):
        print(n, item["sha256"], int(item.get("bytes") or 0))
    break  # only the newest: an older one is not worth a gap in the order
PY
) || true
if [ -z "${name:-}" ]; then
  exit 0  # nothing new to take; the ping went out when the newest came
fi

part="$dir/.$name.part"
trap 'rm -f "$tmp" "$part"' EXIT
curl -fsS --max-time 1800 --max-filesize "$max_bytes" -H @"$header" \
  -o "$part" "$CELL_URL/backups/$name"
told="$(curl -fsS --max-time 30 -H @"$header" "$CELL_URL/backups/$name.sha256" | awk '{print $1}')"
got="$(sha256sum "$part" | awk '{print $1}')"
magic="$(head -c 21 "$part")"
if [ "$got" != "$told" ] || [ "$got" != "$want" ] || [ "$(stat -c %s "$part")" != "$size" ] \
  || [ "$magic" != "age-encryption.org/v1" ]; then
  echo "$name: the sum, the size or the header does not match (got $got, told $told, listed $want)" >&2
  push down "$name: checksum mismatch"
  exit 1
fi
mv -n "$part" "$dir/$name"  # never over a package already here
printf '%s  %s\n' "$got" "$name" > "$dir/$name.sha256"
echo "pulled $name ($size bytes, sha256 $got)"

# Thirty days, but never fewer than the newest seven, and the newest of each month for a
# year: a month without backups, or a month of junk from a cell gone wrong, must not leave
# nothing good behind.
python3 - "$dir" "$cell" "$keep_days" "$keep_min" <<'PY'
import datetime as dt, os, re, sys
d, cell, days, keep_min = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
shape = re.compile(re.escape(cell) + r"-([0-9]{8})-([0-9]{4})\.tar\.gz\.age")
found = sorted((n for n in os.listdir(d) if shape.fullmatch(n)), reverse=True)
now = dt.datetime.now(dt.UTC)
keep = set(found[:keep_min])
months: dict[str, str] = {}
for n in found:
    months.setdefault(shape.fullmatch(n).group(1)[:6], n)  # newest first: the month's newest
keep |= set(sorted(months.values(), reverse=True)[:12])
for n in found:
    day = dt.datetime.strptime(shape.fullmatch(n).group(1), "%Y%m%d").replace(tzinfo=dt.UTC)
    if n not in keep and now - day > dt.timedelta(days=days):
        for f in (n, n + ".sha256"):
            try:
                os.remove(os.path.join(d, f))
            except FileNotFoundError:
                pass
        print(f"removed {n}, older than {days} days")
PY
push up "$name"
