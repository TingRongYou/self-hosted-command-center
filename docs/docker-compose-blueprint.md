# Docker Compose Blueprint

This document serves as the master architecture blueprint for the server stack. It defines the routing, persistent storage bindings, and configuration parameters for all deployed services. 

## Network & Routing Architecture
The server utilizes Tailscale for secure, zero-trust remote access. All incoming web traffic is routed through the host network to specific container ports.

| Host Port | Protocol | Service | Purpose |
| :--- | :--- | :--- | :--- |
| **80** | TCP | `homepage` | Main entry point and centralized dashboard |
| **53** | TCP/UDP | `pihole` | Network-wide DNS resolution and ad-blocking |
| **8080** | TCP | `nextcloud_vault` | File storage and cloud access |
| **8081** | TCP | `pihole` | DNS administrative web interface |
| **8082** | TCP | `speedtest` | Automated network speed tracking |
| **8083** | TCP | `vaultwarden` | Password manager web interface |

*(Note: The `glances` container bypasses standard port mapping by utilizing `network_mode: host` to directly monitor the physical host's network interfaces and system resources.)*

## Volume & State Management
The architecture strictly enforces the separation of stateful data and stateless configurations.

*   **Stateful Data (External Storage):** Services that manage user data (Nextcloud, Vaultwarden) are strictly bound to the external USB mount (`/mnt/usb_vault`). If the container is destroyed, the user data remains safely intact on the physical disk.
*   **Stateless Configurations (Local Directory):** Services that require structural configuration (Homepage, Pi-hole, Speedtest) use relative bindings (`./`) to the local project directory. These files can be safely checked into version control or backed up easily.
*   **System Integration:** `homepage` mounts the host's Docker socket (`/var/run/docker.sock`) in read-only mode (`:ro`) to fetch real-time container statuses and API metrics safely.

## Service Breakdown

### 1. Homepage (`homepage`)
*   **Purpose:** The central navigation hub for the server.
*   **Security:** Restricts access via the `HOMEPAGE_ALLOWED_HOSTS` environment variable to ensure only authorized local and Tailscale IP addresses can render the dashboard.
*   **Configuration:** Relies entirely on the stateless `./homepage/config` directory for its visual layout and service definitions.

### 2. Glances (`glances`)
*   **Purpose:** Comprehensive system resource monitoring.
*   **Integration:** Runs in full host mode (`pid: host`, `network_mode: host`) to grant the container deep visibility into the host machine's CPU, memory, and disk I/O metrics. The `-w` flag enables the built-in web server.

### 3. Nextcloud (`nextcloud_vault`)
*   **Purpose:** Self-hosted cloud storage and media synchronization.
*   **Storage:** Binds its core web directory directly to `/mnt/usb_vault/nextcloud_data`, ensuring all photo auto-uploads and databases are physically written to the external drive.

### 4. Pi-hole (`pihole`)
*   **Purpose:** Network-wide DNS sinkhole and ad-blocker.
*   **DNS Resolution:** Configured to listen on all interfaces (`FTLCONF_dns_listeningMode=All`) and utilizes `1.1.1.1` as its upstream fallback resolver.
*   **Storage:** Local project folders (`./pihole/etc-pihole` and `./pihole/etc-dnsmasq.d`) ensure DNS records and blocklists survive container restarts.

### 5. Speedtest Tracker (`speedtest`)
*   **Purpose:** Automated internet performance monitoring.
*   **Automation:** Executes a scheduled bandwidth test every hour (`SPEEDTEST_SCHEDULE=0 * * * *`) and stores the historical performance data in a local SQLite database.

### 6. Vaultwarden (`vaultwarden`)
*   **Purpose:** Lightweight Bitwarden-compatible password manager.
*   **Configuration:** WebSockets are explicitly enabled to allow real-time password syncing across browser extensions and mobile apps.
*   **Storage:** Binds directly to `/mnt/usb_vault/vaultwarden_data` to ensure the encrypted password vaults are permanently stored on external media.

## Secrets Management
Sensitive environment variables—including database passwords, Tailscale IPs, API keys, and admin tokens—are entirely abstracted from this blueprint. All relevant containers source their sensitive parameters dynamically from a single, git-ignored file located at `./homepage/config/secrets.env`.
