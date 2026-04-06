# Final Infrastructure Access Model Map

| Path | Owner:Group | Standard Permissions | ACL Exceptions / Notes |
| :--- | :--- | :--- | :--- |
| `/opt/kijanikiosk/` | `root:root` | `755` (drwxr-xr-x) | Stripped the previous 777 permissions. |
| `/opt/kijanikiosk/api/` | `kk-api:kk-api` | `750` (drwxr-x---) | No ACLs. Only API user can read/execute. |
| `/opt/kijanikiosk/payments/` | `kk-payments:kk-payments` | `750` (drwxr-x---) | No ACLs. Isolated payment code. |
| `/opt/kijanikiosk/config/` | `root:kijanikiosk` | `750` (drwxr-x---) | `user:chela:r-x` |
| `/opt/kijanikiosk/shared/logs/` | `kk-logs:kk-logs` | `2770` (drwxrws---) | `user:kk-api:rwx`, `user:kk-payments:r-x`, `user:chela:r-x` (Sticky bit ensures files inherit the `kk-logs` group). |
| `/opt/kijanikiosk/health/` | `root:kijanikiosk` | `750` (drwxr-x---) | Allows monitoring apps in the `kijanikiosk` group to traverse and read health check outputs. |