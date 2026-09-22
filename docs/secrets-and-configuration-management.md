# Secrets and Configuration Management

## 1. Environment Variable Injection
To maintain repository security, no sensitive keys or passwords are hardcoded into the `docker-compose.yml` file. Instead, the server utilizes environment variable injection.

*   **The Secrets File:** All API keys, administrator passwords, and Tailscale IP addresses are centrally stored in `~/dashboard-project/homepage/config/secrets.env`.
*   **The Injection Method:** The `docker-compose.yml` file maps this file to the relevant containers using the `env_file:` directive. When the container boots, Docker reads the variables from the file and injects them securely into the container's memory.
*   **Version Control Protection:** The `.gitignore` file strictly excludes `*.env` files from being tracked by Git[cite: 5]. A sanitized template file (`secrets.env.example`) is maintained in the repository for reference[cite: 5].

### Redacted `secrets.env` Template
```env
HOMEPAGE_VAR_SERVER_IP=<TAILSCALE_IP>
HOMEPAGE_VAR_SERVER_HOSTNAME=<TAILSCALE_IP>

HOMEPAGE_VAR_PIHOLE_KEY=<REDACTED_API_KEY>
FTLCONF_webserver_api_password=<REDACTED_PASSWORD>

APP_KEY=base64:<REDACTED_APP_KEY>
HOMEPAGE_VAR_SPEEDTEST_KEY=<REDACTED_SPEEDTEST_KEY>

ADMIN_TOKEN=<REDACTED_VAULTWARDEN_ADMIN_TOKEN>
HOMEPAGE_VAR_VAULTWARDEN_URL=https://<TAILNET_NAME>.ts.net
```

## 2. Nextcloud Cryptographic Recovery (`rescue_config.php`)
The `rescue_config.php` file is a critical, standalone backup of the Nextcloud instance's core cryptographic keys. 

If the Nextcloud container or the external database is entirely lost, restoring this specific file allows the server to recognize the existing file structures and decrypt the database. 

*   **Critical Variables:** The `instanceid`, `passwordsalt`, and `secret` parameters are unique to this specific server deployment. If these are lost, user passwords and encrypted data cannot be recovered, even if the raw database files exist.

### Redacted `rescue_config.php` Template
```php
<?php
$CONFIG = array (
  'htaccess.RewriteBase' => '/',
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'apps_paths' => 
  array (
    // ... Path configurations ...
  ),
  'instanceid' => '<REDACTED_INSTANCE_ID>',
  'passwordsalt' => '<REDACTED_PASSWORD_SALT>',
  'secret' => '<REDACTED_SECRET_KEY>',
  'trusted_domains' => 
  array (
    0 => '192.168.100.5:8080',
    1 => '<TAILSCALE_IP>',
  ),
  'datadirectory' => '/var/www/html/data',
  'dbtype' => 'sqlite3',
  'version' => '33.0.3.2',
  // ... Standard environment configurations ...
);
```

## 3. Secure Backup Protocol
Because these files contain the master keys to the server (including the Vaultwarden administrator token and Pi-hole authentication), they must be backed up securely.

*   **Automated Off-site Storage:** The `backup.sh` script automatically packages the entire `~/dashboard-project` directory—including `secrets.env` and `rescue_config.php`—and streams it directly to Google Drive via `rclone`.
*   **Zero Git Exposure:** These files reside locally on the host and in the encrypted Google Drive archive. They are strictly prohibited from being pushed to the public GitHub repository.
