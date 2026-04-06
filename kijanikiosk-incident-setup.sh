#!/bin/bash
# kijanikiosk-incident-setup.sh
set -euo pipefail
echo "[setup] Injecting faults into staging server..."

# FAULT 1: Disk I/O saturation
mkdir -p /opt/kijanikiosk/shared/logs
dd if=/dev/urandom bs=1M count=512 of=/opt/kijanikiosk/shared/logs/payments-2024-03-10.log status=progress
dd if=/dev/urandom bs=1M count=512 of=/opt/kijanikiosk/shared/logs/payments-2024-03-14.log status=progress
dd if=/dev/urandom bs=1M count=512 of=/opt/kijanikiosk/shared/logs/payments-2024-03-17.log status=progress
chown kk-logs:kijanikiosk /opt/kijanikiosk/shared/logs/*.log

# FAULT 2: Port conflict
cat > /tmp/rogue-server.js << 'NODEOF'
const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(500, {'Content-Type': 'application/json'});
  res.end(JSON.stringify({ error: 'Internal Server Error', service: 'unknown' }));
});
server.listen(3001, '127.0.0.1', () => {
  console.log('Rogue server listening on 127.0.0.1:3001');
});
NODEOF
nohup node /tmp/rogue-server.js >/tmp/rogue-server.log 2>&1 &

# FAULT 3: Firewall misconfiguration
ufw deny 3001/tcp comment 'MISCONFIGURED: blocks health checks'
ufw reload

echo "[setup complete] Three faults are now active."
