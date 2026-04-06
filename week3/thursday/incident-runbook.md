# Incident Report: KijaniKiosk Staging 502 Errors
**Start Time:** Monday, April 6, 2026, 10:01 PM

## Phase 1: Performance Layer
**Investigation Start Time:** 10:01 PM

### Performance Metrics (Baseline):
* **Top Results:**
    * [cite_start]System I/O Wait (`wa`): 0.0% [cite: 733]
    * Highest Resource Process: PID 7793, User: chela, State: S (sleeping), %CPU: 56.0% (Chrome)
* **vmstat Samples:**
    * [cite_start]`b` (blocked) column values: 0, 0, 0, 0, 0 [cite: 795]
    * [cite_start]`si/so` (swap) activity: 0 / 0 [cite: 795]
    * Trend: Stable (Healthy baseline)
* **iostat Results:**
    * Device: nvme0n1
    * [cite_start]%util: ~1.3% [cite: 838]
    * [cite_start]await: < 1.0ms [cite: 839]
* **Disk Capacity:**
    * `/` Usage: [Insert result of df -h /]
    * Shared Logs Size: [Insert result of du -sh /opt/kijanikiosk/shared/logs/]

### Initial Hypothesis
**Timestamp:** 10:08 PM
[cite_start]**Hypothesis:** The system is currently in a healthy baseline state because the fault injection script has not yet been executed; once executed, I expect I/O wait to exceed 50% due to simulated log accumulation[cite: 1349].

---
## Phase 2: Log Layer
* **kk-payments errors:** [To be completed after fault injection]
* [cite_start]**Kernel/Disk errors:** [Check /var/log/kern.log for "ata" or "I/O error"] [cite: 1402]
* [cite_start]**Logrotate status:** No config found in /etc/logrotate.d/kijanikiosk [cite: 1404]

## Phase 3: Network Layer
* [cite_start]**Port 3001 Audit:** [Run ss -tlnp | grep 3001] [cite: 1418]
* [cite_start]**Firewall Audit:** [Run sudo ufw status numbered] [cite: 1422]

## Phase 4: Remediation
1. [cite_start]**Fix Port Conflict:** [Identify PID, check state, and choose SIGTERM or SIGKILL] [cite: 1430-1434]
2. [cite_start]**Fix Firewall:** [Delete the injected deny rule] [cite: 1440]
3. [cite_start]**Fix Disk I/O:** [Force logrotate and update provisioning script] [cite: 1449-1460]

## Phase 5: Verification
* [cite_start]**Final performance:** [Expected wa < 10%, b = 0] [cite: 1474-1475]
* [cite_start]**Final network:** [Expected one listener on 3001, no deny rule] [cite: 1481-1484]


## Phase 2: Log Layer
**Investigation Time:** 10:15 PM

### Log Evidence:
* **kk-payments journal:** `-- No entries --`. [cite_start]This indicates the service is likely hung and unable to process or log requests.
* **Nginx Error Log:** No recent upstream errors found. The log shows a clean start from April 1st.
* **Kernel Logs (/var/log/kern.log):** Found standard SCSI and libata initialization messages. [cite_start]No active hardware `I/O error` or `ata` resets found, confirming the saturation is software-driven log accumulation, not a failing physical disk[cite: 932].
* **Logrotate Configuration:** `no logrotate config found`. [cite_start]This confirms a critical maintenance failure; the server has no automated way to reclaim space[cite: 1052, 1078].
* **Shared Logs Directory Size:** **1.5GB total** (3 files at 513MB each). [cite_start]These are the files injected by the setup script simulating weeks of unrotated logs [cite: 1315-1318].

### Revised Hypothesis
**Timestamp:** 10:18 PM
**Hypothesis:** The HTTP 502 errors are caused by extreme disk I/O pressure. [cite_start]While the kernel and hardware appear healthy, the lack of a logrotate configuration has allowed 1.5GB of log data to accumulate, saturating the disk's write bandwidth and causing the kk-payments service to hang[cite: 1089, 1090].


## Phase 3: Network Layer
**Investigation Time:** 10:13 PM

### Network Findings:
* **Port 3001 Audit:** Found a rogue process bound to `127.0.0.1:3001` with **PID 96592**. 
* **Rogue Process Details:**
    * **PID:** 96592
    * **User:** chela
    * **Command:** `node /tmp/rogue-server.js` (Started via nohup)
* **Localhost Response:** `curl` returned `HTTP/1.1 500 Internal Server Error` with the body `{"error":"Internal Server Error","service":"unknown"}`. This proves the rogue process is intercepting local traffic intended for kk-payments.
* **Firewall Audit:** Rule **[ 5]** is an explicit `DENY IN Anywhere` for port `3001/tcp` with the comment `# MISCONFIGURED: blocks health checks`.
* **External Interface Test:** Connection to `192.168.8.55:3001` failed with `Connection refused`. This confirms the firewall is actively blocking external health probes.

### Root Cause Summary
1. **Disk I/O Saturation (Performance/Log Layer):** 1.5GB of unrotated log data is saturating the disk, causing the system to hang.
2. **Port Conflict (Network Layer):** Rogue Node.js process (PID 96592) is bound to loopback on 3001, causing 500 errors for internal requests.
3. **Firewall Block (Network Layer):** UFW rule #5 blocks port 3001 on the external interface, causing the monitoring system to mark the node as unhealthy.

## Phase 4: Remediation (Continued)
* **Fix 1 (Port Conflict):**
    * **Process State:** `Sl` (Interruptible sleep, multi-threaded).
    * **Signal Used:** `SIGKILL` (-9). [cite_start]Note: Initially used SIGKILL to ensure immediate port release given the `Sl` state [cite: 1431-1434].
    * **Verification:** `ss -tlnp | grep 3001` returned empty, confirming the rogue process is gone.
* **Fix 2 (Firewall):**
    * **IPv4 Rule:** Deleted rule #5.
    * **IPv6 Rule:** Deleted remaining deny rule for 3001/tcp.
    * **Result:** Firewall now only contains intended ALLOW rules.
* **Fix 3 (Log Saturation):**
    * **Action:** Ran updated provisioning script to deploy the missing `/etc/logrotate.d/kijanikiosk` config.
    * **Manual Force:** Executed `logrotate --force` to immediately reclaim disk space.


