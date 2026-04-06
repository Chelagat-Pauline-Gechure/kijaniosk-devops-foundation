# KijaniKiosk Access Model Design & Reasoning

| Directory / File | Owner:Group | Mode | Additional ACLs | Engineering Reasoning |
| :--- | :--- | :--- | :--- | :--- |
| `/opt/kijanikiosk/api/` | `kk-api:kk-api` | 750 | `amina: r-x` | **Mode/Group:** 750 ensures only the API service (owner) can write, while restricting world access. **ACL vs Basic:** We use an ACL for the operator (`amina`) so she can read/traverse the directory for troubleshooting without needing to be added to the service's primary group. |
| `/opt/kijanikiosk/payments/` | `kk-payments:kk-payments` | 750 | `amina: r-x` | **Mode/Group:** Same isolation principle as the API directory. The payments service owns its execution environment. |
| `/opt/kijanikiosk/logs/` | `kk-logs:kk-logs` | 750 | `amina: r-x` | **Mode/Group:** Dedicated environment for the log aggregator process. |
| `/opt/kijanikiosk/config/` | `root:kijanikiosk` | 750 (dir) <br> 640 (files) | `amina: r-x` | **Mode/Group:** `root` owns these files so compromised application processes cannot overwrite their own configurations. The `kijanikiosk` group is assigned so all three services can read the credentials. **Mode:** 640 prevents world-reading of secrets. |
| `/opt/kijanikiosk/shared/logs/` | `kk-logs:kk-logs` | 2770 (SGID) | `kk-api: rwx`<br>`kk-payments: r-x`<br>`amina: r-x` | **Mode/Group:** SGID (2xxx) ensures any files written here automatically inherit the `kk-logs` group, allowing the log aggregator to process them. **ACL vs Basic:** ACLs are mandatory here because multiple distinct services need varying levels of access (API needs write, Payments needs read) to a directory owned by a third service. |
| `/opt/kijanikiosk/scripts/deploy.sh` | `root:root` | 750 | None | **Mode/Group:** Stripped the dangerous SUID bit and world-write access. 750 ensures only `root` can modify or execute the deployment script, preventing unprivileged payload injection. |
