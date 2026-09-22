# Server Infrastructure Map

## Hardware & Host OS
* **Host Device:** Presario V3700 Notebook
* **OS:** Ubuntu 26.04 (Resolute Raccoon) x86_64
* **Network:** Tailscale for secure remote access

## Directory Architecture
The server architecture is explicitly split into two storage locations to separate stateless application configurations from stateful persistent data.

### 1. Stateless Configuration (The Repository)
**Path:** `~/dashboard-project` (or `SelfHostedCommandCenter`)
This directory contains the declarative configuration files required to deploy the stack[cite: 5]. It is designed to be ephemeral and can be cloned directly from GitHub.
* `docker-compose.yml`: The master blueprint for all Docker containers[cite: 5].
* `backup.sh`: The automated backup script that streams stateful data and configurations directly to Google Drive[cite: 5].
* `homepage/config/`: Contains the dashboard layout UI (`settings.yaml`, `widgets.yaml`, `services.yaml`, `custom.css`, `custom.js`) and the sensitive `secrets.env` file[cite: 5].

### 2. Stateful Data (External Mount)
**Path:** `/mnt/usb_vault`
This external USB drive isolates all persistent databases, user uploads, and application states.
* `/mnt/usb_vault/vaultwarden_data`: Contains the SQLite databases and cryptographic keys for the password manager.
* `/mnt/usb_vault/nextcloud_data`: Contains the Nextcloud application state and user data.
  * `/mnt/usb_vault/nextcloud_data/data/Tries`: The designated daily user profile containing the primary media payload (auto-uploaded photos and videos).

## Startup Sequencing & Dependencies
To prevent empty-mount race conditions after electrical outages, a custom `systemd` override controls the boot sequence. 

* **Docker Override Path:** `/etc/systemd/system/docker.service.d/override.conf`
* **Dependency Rule:** The Docker daemon is strictly dependent on `mnt-usb_vault.mount`. It will wait for the external USB drive to fully mount before initiating the container stack, ensuring Docker never writes persistent data to the host's internal drive.
