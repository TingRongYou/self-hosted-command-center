#!/bin/bash

# Enforce running the script as root to prevent timeouts
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script using sudo (sudo ./backup.sh)"
  exit 1
fi

# Define variables
DATE=$(date +"%Y-%m-%d")
BACKUP_FILENAME="server_backup_$DATE.tar.gz"
GDRIVE_DEST="gdrive:5. Server Backup"

echo "Starting backup process..."

# 1. Stop the entire Docker stack safely so files don't change during the backup
cd /home/tingrongyou/dashboard-project
docker compose stop

# 2. Compress and stream directly to Google Drize (Zero local storage used)
echo "Streaming backup directly to Google Drive..."
tar -czf - /mnt/usb_vault /home/tingrongyou/dashboard-project | rclone --config /home/tingrongyou/.config/rclone/rclone.conf rcat "$GDRIVE_DEST/$BACKUP_FILENAME"

# 3. Bring the server back online
docker compose up -d

echo "Backup stream complete and uploaded to Google Drive!"
