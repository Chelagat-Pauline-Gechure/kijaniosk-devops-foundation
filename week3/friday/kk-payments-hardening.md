# Technical Hardening Log: kk-payments.service

**Starting Security Score:** ~9.6 (UNSAFE)

### Directives Added for Hardening:
* `ProtectSystem=strict`: Mounts the entire filesystem as read-only for the service.
* `ReadWritePaths=...`: Exception to the above; allows the service to write its logs.
* `ProtectHome=yes`: Denies access to `/home`, `/root`, and `/run/user`.
* `PrivateTmp=yes`: Mounts a completely isolated `/tmp` directory.
* `PrivateDevices=yes`: Hides physical hardware devices in `/dev` from the service.
* `ProtectKernelTunables=yes` & `ProtectKernelModules=yes`: Prevents modification of kernel variables.
* `ProtectKernelLogs=yes` & `ProtectClock=yes`: Restricts access to dmesg and system time alteration.
* `RestrictNamespaces=yes` & `RestrictRealtime=yes`: Prevents namespace manipulation and real-time process scheduling.
* `RestrictSUIDSGID=yes`: Prevents the creation of set-user-ID or set-group-ID files.
* `MemoryDenyWriteExecute=yes`: Prevents dynamic generation of executable code in memory.
* `LockPersonality=yes`: Locks down execution domain.
* `NoNewPrivileges=yes`: Ensures the process and its children can never gain new privileges.
* `RemoveIPC=yes`: Ensures no lingering SysV IPC objects are left after termination.
* `RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX`: Restricts socket creation to necessary networking and local IPC.
* `SystemCallFilter=@system-service`: Whitelists standard, safe system calls.
* `CapabilityBoundingSet=` & `AmbientCapabilities=`: Drops all Linux root capabilities entirely.

### Directives Explicitly Rejected:
1. **`PrivateNetwork=yes`**: Rejected because `kk-payments` relies on `AF_INET` to expose port 3001 and needs to communicate over the local loopback interface. Setting this would cut off its required network capabilities.
2. **`DynamicUser=yes`**: Rejected because we have explicitly defined ACLs mapped to the static `kk-payments` user (UID 994) in `/opt/kijanikiosk/shared/logs`. A dynamic user would break our predictable ACL mapping and log rotation mechanisms.

### Final Configuration (`< 2.5` Score achieved)
```ini
[Unit]
Description=KijaniKiosk Payments Service
After=network.target kk-api.service
Wants=kk-api.service

[Service]
Type=simple
User=kk-payments
Group=kijanikiosk
ExecStart=/usr/bin/node /opt/kijanikiosk/payments/app.js
Restart=on-failure

ProtectSystem=strict
ReadWritePaths=/opt/kijanikiosk/shared/logs/
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
ProtectKernelLogs=yes
ProtectClock=yes
RestrictNamespaces=yes
RestrictRealtime=yes
RestrictSUIDSGID=yes
MemoryDenyWriteExecute=yes
LockPersonality=yes
NoNewPrivileges=yes
RemoveIPC=yes
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM
CapabilityBoundingSet=
AmbientCapabilities=

[Install]
WantedBy=multi-user.target  