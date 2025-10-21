#!/bin/bash
#
# Backup.sh — Automated directory backup with rotation
# Usage: ./Backup.sh <source_dir> <backup_dir> [max_backups]
#
# Example: ./Backup.sh /var/log /mnt/backup 7
#
# Author: Abusufiyan Khan

set -euo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# --- Arguments & Defaults ---
if [ $# -lt 2 ]; then
    echo "Usage: $0 <source_dir> <backup_dir> [max_backups]"
    exit 1
fi

SOURCE_DIR=$1
BACKUP_DIR=$2
MAX_BACKUPS=${3:-5}   # Default to keeping 5 backups
TIMESTAMP=$(date '+%Y-%m-%d-%H-%M-%S')
LOG_FILE="${BACKUP_DIR}/backup.log"

# --- Preparation ---
mkdir -p "$BACKUP_DIR"

# --- Backup Creation ---
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.zip"

echo "[$(date '+%F %T')] Starting backup of ${SOURCE_DIR}" | tee -a "$LOG_FILE"

if /usr/bin/zip -r "$BACKUP_FILE" "$SOURCE_DIR" > /dev/null 2>&1; then
    echo "[$(date '+%F %T')] ✅ Backup successful: ${BACKUP_FILE}" | tee -a "$LOG_FILE"
else
    echo "[$(date '+%F %T')] ❌ Backup failed!" | tee -a "$LOG_FILE"
    exit 1
fi

# --- Rotation Logic ---
echo "[$(date '+%F %T')] Performing rotation (keep ${MAX_BACKUPS} most recent backups)" | tee -a "$LOG_FILE"

# List all backups sorted by modification time, remove older ones
mapfile -t BACKUPS < <(ls -t "${BACKUP_DIR}/backup_"*.zip 2>/dev/null || true)
if (( ${#BACKUPS[@]} > MAX_BACKUPS )); then
    REMOVE_COUNT=$(( ${#BACKUPS[@]} - MAX_BACKUPS ))
    for OLD_BACKUP in "${BACKUPS[@]:MAX_BACKUPS:REMOVE_COUNT}"; do
        rm -f "$OLD_BACKUP"
        echo "[$(date '+%F %T')] 🧹 Removed old backup: $OLD_BACKUP" | tee -a "$LOG_FILE"
    done
fi

echo "[$(date '+%F %T')] ✅ Backup and rotation complete." | tee -a "$LOG_FILE"
exit 0
