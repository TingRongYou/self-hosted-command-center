# Disaster Recovery Playbook

## 1. Backup Architecture & Scope
The automated backup pipeline (`backup.sh`) is designed to capture the entire server state without consuming any local disk space. 

*   **Zero-Storage Pipeline:** Instead of writing a massive `.tar.gz` archive to the host's internal storage, the script streams the compressed data via `rclone rcat` directly to Google Drive. This prevents disk-full crashes.
*   **Comprehensive Scope:** The backup captures both the stateful payload and the stateless configurations simultaneously.
    *   **Stateful Data:** Captures the entirety of `/mnt/usb_vault`, which includes the Vaultwarden databases and the Nextcloud media payload (specifically the primary `Tries` user profile).
    *   **Stateless Configurations:** Captures `/home/tingrongyou/dashboard-project`, ensuring all Docker Compose blueprints and sensitive `secrets.env` keys are saved.
*   **Execution:** The script must be executed with root privileges (`sudo`) to prevent standard user timeouts and ensure full read access to system databases.

## 2. The Restore Process
If catastrophic data loss occurs (e.g., hard drive failure or total database corruption), follow these exact steps to rebuild the server state from the Google Drive archive.

**Step 1: Halt All Services**
Before touching any files, completely shut down the Docker stack to prevent active database writes.
```bash
cd /home/tingrongyou/dashboard-project
sudo docker compose stop
```

**Step 2: Retrieve the Archive**
Download the latest `server_backup_YYYY-MM-DD.tar.gz` archive from the `5. Server Backup` folder in Google Drive to the server's root or a staging directory.

**Step 3: Extract and Restore Data**
Extract the archive directly into the root directory (`/`). Because the backup was created with absolute paths (stripped of the leading slash), extracting to `/` will automatically drop the `mnt/usb_vault` and `home/tingrongyou/dashboard-project` folders exactly where they belong. The `-p` flag ensures all original file permissions are preserved.
```bash
sudo tar -xzpf server_backup_YYYY-MM-DD.tar.gz -C /
```

**Step 4: Verify Nextcloud Ownership**
Nextcloud requires strict ownership rules to function. Ensure the restored Nextcloud data directory is owned by the `www-data` web user.
```bash
sudo chown -R www-data:www-data /mnt/usb_vault/nextcloud_data
```

**Step 5: Rescan Nextcloud Database (if necessary)**
If Nextcloud failes to display historical photos after a restore, force the application to rebuild its file index.
```bash
sudo docker exec --user www-data -it nextcloud_vault php occ files:scan --all
```

**Step 6: Bring the Stack Online**
Once all files are restored and permissions are verified, restart the infrastructure.
```bash
cd /home/tingrongyou/dashboard-project
sudo docker compose up -d
```
