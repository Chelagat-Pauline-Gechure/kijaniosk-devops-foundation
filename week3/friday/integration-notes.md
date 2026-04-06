# Engineering Integration Notes

### A. The Configuration Conflict (`ProtectSystem=strict` vs `EnvironmentFile`)
**The Challenge:** `ProtectSystem=strict` makes the entire filesystem read-only to the service. We needed to ensure the service could still read its config files while simultaneously writing to the log directory.
**The Solution:** `ProtectSystem=strict` allows reading by default, so reading configurations from `/opt/kijanikiosk/config/` is unaffected. However, it blocks writing. We bypassed this specifically for logs using the `ReadWritePaths=/opt/kijanikiosk/shared/logs/` directive, granting narrow write access to just that directory.

### B. The Monitoring User Catch-22
**The Challenge:** We created `/opt/kijanikiosk/health/` with `750` permissions and `root:kijanikiosk` ownership, but the monitoring tool needs to read `last-provision.json` without `sudo`.
**The Solution:** Because the monitoring tool shares the `kijanikiosk` group, it can traverse the `750` directory. By setting the file ownership to `root:kijanikiosk` and permissions to `640`, any user in the `kijanikiosk` group (including our monitoring system) can read the JSON payload natively without needing privilege escalation.

### C. Logrotate and `PrivateTmp`
**The Challenge:** `kk-logs` uses `PrivateTmp=true`. Logrotate typically restarts services during a `postrotate` phase using systemd.
**The Solution:** We used `systemctl try-restart kk-logs.service` in the `postrotate` block of `/etc/logrotate.d/kijanikiosk`. This safely recycles the service and its temporary namespace without causing conflicts, ensuring the service releases the old file descriptor and attaches to the newly rotated log file.

### D. Hardening `< 2.5`
**The Challenge:** Applying enough directives to drop the score without breaking Node.js functionality.
**The Solution:** Iteratively applied sandboxing rules. We specifically avoided `PrivateNetwork=yes` to maintain API loopback communication and utilized `CapabilityBoundingSet=` (empty) to strip all root privileges, resulting in an ultra-secure score while keeping the application fully operational.