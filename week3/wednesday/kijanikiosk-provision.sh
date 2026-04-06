#!/bin/bash
# kijanikiosk-provision.sh
# Idempotent provisioning for KijaniKiosk application servers.
# Usage: sudo bash kijanikiosk-provision.sh

set -euo pipefail

readonly NGINX_VERSION="1.26.3-2ubuntu1.2"
readonly NODE_MAJOR_VERSION="20"
readonly APP_GROUP="kijanikiosk"
readonly APP_BASE="/opt/kijanikiosk"

log() { echo "[$(date +%FT%T)] INFO: $*"; }
success() { echo "[$(date +%FT%T)] OK: $*"; }
error() { echo "[$(date +%FT%T)] ERROR: $*" >&2; exit 1; }

[ $EUID -ne 0 ] && error "Must run as root or with sudo"
grep -qi ubuntu /etc/os-release || error "Designed for Ubuntu only"

log "Starting KijaniKiosk provisioning..."

provision_packages() {
    log "=== Phase 1: Packages ==="
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get update -qq
    apt-get install -y --no-install-recommends curl gnupg acl ufw

    if [ ! -f /usr/share/keyrings/nodesource.gpg ]; then
        log "Adding NodeSource repository..."
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg
        echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
        apt-get update -qq
    fi

    log "Installing nginx and nodejs..."
    apt-get install -y --no-install-recommends "nginx=${NGINX_VERSION}" nodejs
    
    # Idempotent package holding
    dpkg -l nginx 2>/dev/null | grep -q "^ii" && apt-mark hold nginx || true
    dpkg -l nodejs 2>/dev/null | grep -q "^ii" && apt-mark hold nodejs || true
}

provision_users() {
    log "=== Phase 2: Service Accounts ==="
    getent group "$APP_GROUP" >/dev/null 2>&1 || groupadd "$APP_GROUP"

    for svc in kk-api kk-payments kk-logs; do
        if ! id "$svc" >/dev/null 2>&1; then
            useradd --system --no-create-home --home-dir /nonexistent \
                    --shell /usr/sbin/nologin --comment "KijaniKiosk $svc Service" "$svc"
            log "Created account: $svc"
        else
            log "Already exists: $svc"
        fi
        usermod -aG "$APP_GROUP" "$svc"
    done
}

provision_dirs() {
    log "=== Phase 3: Directories ==="
    mkdir -p "$APP_BASE"/{api,payments,logs,config,scripts,shared/logs}

    # Ownership
    chown kk-api:kk-api "$APP_BASE/api"
    chown kk-payments:kk-payments "$APP_BASE/payments"
    chown kk-logs:kk-logs "$APP_BASE/logs"
    chown root:"$APP_GROUP" "$APP_BASE/config"
    chown kk-logs:kk-logs "$APP_BASE/shared/logs"

    # Modes
    chmod 750 "$APP_BASE/api" "$APP_BASE/payments" "$APP_BASE/logs" "$APP_BASE/config"
    chmod 2770 "$APP_BASE/shared/logs"

    # ACLs
    setfacl -m u:kk-api:rwx "$APP_BASE/shared/logs"
    setfacl -m u:kk-payments:r-x "$APP_BASE/shared/logs"
    setfacl -d -m u:kk-api:rwx "$APP_BASE/shared/logs"
    setfacl -d -m u:kk-payments:r-x "$APP_BASE/shared/logs"
}

provision_services() {
    log "=== Phase 4: systemd Units ==="
    cat > /etc/systemd/system/kk-api.service << 'UNIT'
[Unit]
Description=KijaniKiosk API Service
Wants=network-online.target
After=network-online.target
After=kk-payments.service

[Service]
Type=simple
User=kk-api
Group=kk-api
WorkingDirectory=/opt/kijanikiosk/api
ExecStart=/usr/bin/node /opt/kijanikiosk/api/server.js
ExecReload=/bin/kill -HUP $MAINPID

Restart=on-failure
RestartSec=5s
StartLimitIntervalSec=60s
StartLimitBurst=3
TimeoutStartSec=30s
TimeoutStopSec=30s

StandardOutput=journal
StandardError=journal
SyslogIdentifier=kk-api

# Security Hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
CapabilityBoundingSet=
ReadWritePaths=/opt/kijanikiosk/shared/logs
# Two extra directives to drop score below 3.0
SystemCallFilter=@system-service
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable kk-api.service
}

provision_firewall() {
    log "=== Phase 5: Firewall ==="
    # Reset is allowed to fail if UFW isn't active yet
    ufw --force reset >/dev/null 2>&1 || true
    
    ufw default deny incoming
    ufw default allow outgoing
    
    # CRITICAL: Allow SSH before enabling to prevent lock-out
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 3000/tcp
    
    ufw --force enable
}

verify_state() {
    log "=== Phase 6: Verification ==="
    local failed=0

    # Verify users
    for svc in kk-api kk-payments kk-logs; do
        id "$svc" >/dev/null 2>&1 || { log "FAIL: Missing user $svc"; ((failed++)); }
    done

    # Verify SUID
    local suid_files
    suid_files=$(find "$APP_BASE" -perm /4000 -type f 2>/dev/null)
    if [ -n "$suid_files" ]; then
        log "FAIL: SUID files found in $APP_BASE: $suid_files"
        ((failed++))
    fi

    # Verify held packages
    apt-mark showhold | grep -q "^nginx$" || { log "FAIL: nginx not held"; ((failed++)); }
    apt-mark showhold | grep -q "^nodejs$" || { log "FAIL: nodejs not held"; ((failed++)); }

    # Verify service
    systemctl is-enabled kk-api.service >/dev/null 2>&1 || { log "FAIL: kk-api.service not enabled"; ((failed++)); }

    if [ "$failed" -eq 0 ]; then
        success "All verification checks passed!"
    else
        error "$failed verification check(s) failed."
    fi
}

main() {
    provision_packages
    provision_users
    provision_dirs
    provision_services
    provision_firewall
    verify_state
    success "Provisioning complete. Server is in known state."
}

main "$@"
