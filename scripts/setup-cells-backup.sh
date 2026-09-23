#!/usr/bin/env bash
# LEGACY (2026-09-23): the laptop no longer uploads here — the VPS pulls the backup itself
# (cells decision 0037, scripts/cells-backup-pull.sh). Kept until the pull has run green for a
# week; its packages are copied into the pull directory by setup-cells-backup-pull.sh.
# One-time on the VPS: a drop box for the agent cells' nightly backups (decision 0024 in the
# private repo ku113p/cells). The laptop pushes an encrypted package here over sftp; this user
# can do nothing else — no shell, no port forwarding, and a chroot it cannot escape. The
# packages are encrypted to a key the VPS does not have.
#
#   ssh root@$VPS_HOST 'bash -s' < scripts/setup-cells-backup.sh "<ssh-ed25519 AAAA... comment>"
#
# Re-running is safe.
set -euo pipefail
pubkey="${1:?usage: setup-cells-backup.sh \"<public key line>\"}"
user=cellsbak
root=/opt/services/backup
keep_days=30

id "$user" >/dev/null 2>&1 || useradd --system --shell /usr/sbin/nologin --no-create-home --home-dir "$root" "$user"

# The chroot itself must be root-owned and not writable by the user; the drop box inside it is.
mkdir -p "$root/emp-a"
chown root:root "$root"; chmod 755 "$root"
chown "$user:$user" "$root/emp-a"; chmod 750 "$root/emp-a"

# Keys live outside the chroot, where the user cannot change them.
mkdir -p /etc/ssh/authorized_keys
printf 'restrict %s\n' "$pubkey" > "/etc/ssh/authorized_keys/$user"
chown root:root "/etc/ssh/authorized_keys/$user"; chmod 644 "/etc/ssh/authorized_keys/$user"

# A Match block swallows everything after it, so it goes at the very end of the main file, and
# the config is checked before sshd is asked to reload it.
if ! grep -q "^Match User $user" /etc/ssh/sshd_config; then
  cat >> /etc/ssh/sshd_config <<CONF

# Backup drop box for the agent cells (scripts/setup-cells-backup.sh). Keep this last:
# everything after a Match belongs to that Match.
Match User $user
    AuthorizedKeysFile /etc/ssh/authorized_keys/%u
    ChrootDirectory $root
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
    PermitTunnel no
    PermitTTY no
CONF
fi
sshd -t
systemctl reload ssh

# Keep a month; the laptop keeps the last few, the VM keeps seven.
cat > /etc/cron.daily/cells-backup-rotate <<ROTATE
#!/bin/sh
find $root -mindepth 2 -type f -mtime +$keep_days -delete
ROTATE
chmod +x /etc/cron.daily/cells-backup-rotate

echo "ok: $user -> $root/emp-a (sftp only, chroot, keys in /etc/ssh/authorized_keys/$user)"
ls -la "$root"
