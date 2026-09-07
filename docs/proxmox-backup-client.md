# Proxmox Backup Client helpers (ddubsOS)

This repo installs convenient wrappers around proxmox-backup-client to back up and restore your home directory consistently across hosts.

Helpers installed

- pbs-home-backup: create/update a backup of your home directory (pxar archive)
- pbs-home-ls: list snapshots for your backup group
- pbs-home-last: print the most recent snapshot ID
- pbs-home-restore: restore a specific snapshot to a target directory
- pbs-home-restore-last: restore the most recent snapshot
- pbs-home-ls-all: list all snapshots in the repository (not filtered by BACKUP_ID)
- pbs-home-show: print effective repository, fingerprint, backup-id, source path
- pbs-home-prune: prune snapshots for your group using retention policy
- pbs-home-verify: verify latest (default) or all snapshots in your group

Defaults (override anytime via environment)

- Repository: root@pam@192.168.40.15:8007:PBS-LUN2
- Fingerprint (SHA-256): 4b:c6:2a:49:62:2e:c6:0d:63:0c:d1:b6:8b:78:be:af:28:2a:94:eb:d4:e7:77:ab:d1:af:c9:ea:c9:07:ef:26
- Backup group (BACKUP_ID): <hostname>-dwilliams-home
- Source path: /home/dwilliams

Environment variables (all optional)

- PBS_REPOSITORY: Proxmox Backup Server repository (user@realm@host:port:datastore)
- PBS_FINGERPRINT: SHA-256 fingerprint of the PBS TLS certificate
- PBS_PASSWORD: Password for the PBS user (or API token secret)
- BACKUP_ID: Backup group ID (default: <hostname>-dwilliams-home)
- PBS_ENCRYPTION_KEY_FILE: Path to a client-side encryption key (optional)

The helpers will prompt for PBS_PASSWORD if not provided.

Prerequisites

1) Ensure the TLS fingerprint is correct for your PBS host:
   openssl s_client -connect 192.168.40.15:8007 -servername 192.168.40.15 </dev/null 2>/dev/null \
   | openssl x509 -noout -fingerprint -sha256
   Compare output to the fingerprint above; if it differs, either:
   - export PBS_FINGERPRINT=... in your shell, or
   - update the module default and rebuild.

2) Make sure you have credentials:
   - Password user: root@pam with your PBS root password
   - API token: root@pam!TOKENID with PBS_PASSWORD set to the token secret

Client-side encryption (optional but recommended)

You can encrypt pxar archives on the client; store the key safely.

mkdir -p ~/.config/proxmox-backup
proxmox-backup-client key create --kdf scrypt --out ~/.config/proxmox-backup/home.enc.key
chmod 600 ~/.config/proxmox-backup/home.enc.key
export PBS_ENCRYPTION_KEY_FILE=$HOME/.config/proxmox-backup/home.enc.key

Usage

Set environment (optional; defaults exist):

export PBS_REPOSITORY="root@pam@192.168.40.15:8007:PBS-LUN2"
export PBS_FINGERPRINT="4b:c6:2a:49:62:2e:c6:0d:63:0c:d1:b6:8b:78:be:af:28:2a:94:eb:d4:e7:77:ab:d1:af:c9:ea:c9:07:ef:26"
# Optional: override group if your hostname differs from the configured one
# export BACKUP_ID=ixas-dwilliams-home
read -s PBS_PASSWORD && export PBS_PASSWORD

1) Create a backup of your home directory

pbs-home-backup \
  --exclude '.cache/**' \
  --exclude '.local/share/Trash/**'

Notes:
- You can add more --exclude patterns as needed.
- If PBS_ENCRYPTION_KEY_FILE is set, the backup will be encrypted client-side.

2) List snapshots for your backup group

pbs-home-ls
# Pretty JSON output:
pbs-home-ls --output-format json-pretty

3) Show the most recent snapshot ID

pbs-home-last

4) Restore a specific snapshot to a directory

# Use a snapshot ID from pbs-home-ls or pbs-home-last
pbs-home-restore 2025-09-24T02:10:45Z /home/dwilliams/restore

5) Restore the most recent snapshot to a directory

pbs-home-restore-last /home/dwilliams/restore
# Or omit the target directory to restore into ~/restore-<SNAPSHOT>
pbs-home-restore-last

Restore only a specific file or path

Proxmox Backup Client can selectively restore paths from the pxar archive using --include. Paths are relative to the archive root, which corresponds to your home directory.

# Restore a single file from a specific snapshot
proxmox-backup-client restore \
  --repository "$PBS_REPOSITORY" \
  host/$BACKUP_ID/2025-09-24T02:10:45Z \
  home.pxar \
  /home/dwilliams/restore \
  --allow-existing-dirs \
  --include 'Documents/important.pdf'

# Restore just a subdirectory
proxmox-backup-client restore \
  --repository "$PBS_REPOSITORY" \
  host/$BACKUP_ID/2025-09-24T02:10:45Z \
  home.pxar \
  /home/dwilliams/restore \
  --allow-existing-dirs \
  --include 'Pictures/Wallpapers/**'

Tips:
- Omit --include to restore everything in the archive.
- Use multiple --include switches for multiple files/paths.

6) List all snapshots in the repository (not filtered by BACKUP_ID)

pbs-home-ls-all
# JSON-pretty via the raw command if needed:
proxmox-backup-client snapshot list --repository "$PBS_REPOSITORY" --output-format json-pretty

7) Show the effective configuration for quick debugging

pbs-home-show
# Example output:
# Repository: root@pam@192.168.40.15:8007:PBS-LUN2
# Fingerprint: 4b:c6:...
# Backup ID: ixas-dwilliams-home
# Source: /home/dwilliams

8) Prune (retention policy)

Defaults (override via env): KEEP_LAST=7 KEEP_DAILY=14 KEEP_WEEKLY=8 KEEP_MONTHLY=12

pbs-home-prune
# Or customize on the fly
KEEP_LAST=10 KEEP_DAILY=30 pbs-home-prune

9) Verify backups

# Verify the most recent snapshot (default)
pbs-home-verify

# Verify all snapshots in the group (may take time)
pbs-home-verify all

Using API tokens (recommended for automation)

1) In PBS UI: Datacenter > Permissions > API Tokens
2) Create a token for root@pam (or a dedicated user)
3) Use the token in your environment:

export PBS_REPOSITORY='root@pam!TOKENID@192.168.40.15:8007:PBS-LUN2'
export PBS_PASSWORD='TOKEN_SECRET'

Persisting credentials safely

Avoid placing secrets in world-readable files. Options:
- Use a restricted env file for systemd (600 permissions)
- Use a secret manager (e.g., sops-nix/agenix) if you want fully declarative, encrypted storage

Example: ~/.config/proxmox-backup/pbs-env (chmod 600)

PBS_REPOSITORY=root@pam@192.168.40.15:8007:PBS-LUN2
PBS_FINGERPRINT=4b:c6:2a:49:62:2e:c6:0d:63:0c:d1:b6:8b:78:be:af:28:2a:94:eb:d4:e7:77:ab:d1:af:c9:ea:c9:07:ef:26
# BACKUP_ID=ixas-dwilliams-home  # optionally override
# PBS_ENCRYPTION_KEY_FILE=/home/dwilliams/.config/proxmox-backup/home.enc.key
PBS_PASSWORD=REDACTED_OR_USE_SYSTEMD_SECRET

Automating with systemd (optional)

User service (~/.config/systemd/user/pbs-home-backup.service):

[Unit]
Description=Backup /home/dwilliams to Proxmox Backup Server

[Service]
Type=oneshot
EnvironmentFile=%h/.config/proxmox-backup/pbs-env
ExecStart=/usr/bin/pbs-home-backup \
  --exclude '.cache/**' \
  --exclude '.local/share/Trash/**'

User timer (~/.config/systemd/user/pbs-home-backup.timer):

[Unit]
Description=Daily PBS home backup

[Timer]
OnCalendar=03:00
Persistent=true
Unit=pbs-home-backup.service

[Install]
WantedBy=timers.target

Enable and start:

systemctl --user daemon-reload
systemctl --user enable --now pbs-home-backup.timer
systemctl --user list-timers --all | grep pbs-home-backup

Troubleshooting

- TLS/connect errors (e.g., "client error (Connect)")
  - Verify PBS_FINGERPRINT matches the live server certificate
  - openssl s_client -connect 192.168.40.15:8007 -servername 192.168.40.15 </dev/null 2>/dev/null | openssl x509 -noout -fingerprint -sha256
- Auth errors
  - Ensure PBS_PASSWORD is correct; for tokens, use the token secret
- No output from pbs-home-ls
  - There may be no snapshots yet for your BACKUP_ID; run pbs-home-backup first
- Override without rebuild
  - export PBS_REPOSITORY, PBS_FINGERPRINT, BACKUP_ID in your shell, then run the helpers

That’s it—use the helpers to standardize backups across hosts, while keeping overrides flexible via environment variables.
