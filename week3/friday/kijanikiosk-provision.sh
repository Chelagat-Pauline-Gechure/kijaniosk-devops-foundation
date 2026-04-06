#!/bin/bash
# KijaniKiosk Production Foundation - Remediation & Provisioning
# Run with sudo

set -e # Exit immediately on error

echo "[INFO] Starting KijaniKiosk Provisioning..."

# --- PHASE 1: Users & Groups ---
echo "[INFO] Configuring Users & Groups..."
getent group kijanikiosk >/dev/null || groupadd kijanikiosk
for user in kk-api kk-payments kk-logs; do
    if ! id -u "$user" >/dev/null 2>&1; then
        useradd -r -s /usr/sbin/nologin -g kijanikiosk "$user"
    fi
done

# --- PHASE 2: Directories & ACLs ---
echo "[INFO] Remediating Directories and applying ACLs..."
# Fix the 777 permissions found in the audit
chmod 755 /opt/kijanikiosk
chmod 755 /opt/kijanikiosk/app /opt/kijanikiosk/scripts /opt/kijanikiosk/shared

mkdir -p /opt/kijanikiosk/health
chown root:kijanikiosk /opt/kijanikiosk/health
chmod 750 /opt/kijanikiosk/health

# Clean up ACLs to exact specifications
setfacl -R -b /opt/kijanikiosk/shared/logs # Strip old messy ACLs
chmod 2770 /opt/kijanikiosk/shared/logs # Set group sticky bit
chown kk-logs:kk-logs /opt/kijanikiosk/shared/logs
setfacl -m u:kk-api:rwx,u:kk-payments:r-x,u:chela:r-x /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-api:rwx,u:kk-payments:r-x,u:chela:r-x /opt/kijanikiosk/shared/logs

# --- PHASE 3: Package Management ---
echo "[INFO] Managing Packages..."
# Unhold necessary packages if they were held to allow idempotent installation
apt-mark unhold nginx nodejs >/dev/null 2>&1 || true
apt-get update -yq
apt-get install -yq nginx nodejs acl ufw logrotate

# --- PHASE 4: Firewall (UFW) ---
echo "[INFO] Resetting and applying strict UFW rules..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Apply rules based on intent
ufw allow in from 10.0.1.0/24 to any port 22 proto tcp comment 'Allow SSH from Monitor Subnet'
ufw allow in from 10.0.1.0/24 to any port 80 proto tcp comment 'Allow HTTP from Monitor Subnet'
ufw allow in from 127.0.0.1 to any port 3001 proto tcp comment 'Allow internal kk-payments'
ufw --force enable

# --- PHASE 5: Systemd Units (Handled in Step 2 below) ---
# Assuming the unit files are placed in /etc/systemd/system/
echo "[INFO] Reloading systemd..."
systemctl daemon-reload
# Don't try to start them if the application files don't actually exist yet, 
# but enable them so they start on boot once deployed.
systemctl enable kk-api kk-payments || true

# --- PHASE 6: Journal Persistence & Log Rotation ---
echo "[INFO] Configuring Log Rotation and Journal..."
mkdir -p /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal

# Set Journal Limits to fix the 500MB bloat
sed -i 's/.*SystemMaxUse=.*/SystemMaxUse=100M/' /etc/systemd/journald.conf
systemctl restart systemd-journald

# Write Logrotate Config to handle the 1.6GB log bloat
cat << 'EOF' > /etc/logrotate.d/kijanikiosk
/opt/kijanikiosk/shared/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 kk-logs kijanikiosk
    sharedscripts
    postrotate
        # Gracefully reload the log service to release file handles
        systemctl try-restart kk-logs.service >/dev/null 2>&1 || true
    endscript
}
EOF

# --- PHASE 7: Monitoring Health Checks ---
echo "[INFO] Running Health Checks..."
api_status=$(timeout 1 bash -c "</dev/tcp/localhost/3000" 2>/dev/null && echo "ok" || echo "down")
payments_status=$(timeout 1 bash -c "</dev/tcp/localhost/3001" 2>/dev/null && echo "ok" || echo "down")

printf '{"timestamp":"%s", "kk-api":"%s", "kk-payments":"%s"}\n' \
    "$(date -Is)" "$api_status" "$payments_status" > /opt/kijanikiosk/health/last-provision.json

chown root:kijanikiosk /opt/kijanikiosk/health/last-provision.json
chmod 640 /opt/kijanikiosk/health/last-provision.json

echo "[PASS] Provisioning complete."
