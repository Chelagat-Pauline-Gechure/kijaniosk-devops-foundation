# SUID Misconfiguration Analysis

**1. Why does the kernel ignore SUID on interpreted scripts?**
The Linux kernel ignores the SUID bit on shell scripts to prevent Time-of-Check to Time-of-Use (TOCTOU) race condition attacks. Executing an interpreted script is a multi-step process: the kernel checks permissions, opens the script, reads the interpreter path (like `#!/bin/bash`), and then launches the interpreter to read the file. An attacker could rapidly swap the script with a malicious symlink between the time the kernel checks the permissions and the time the interpreter actually executes the code, effectively hijacking the root execution context.

**2. If the SUID bit has no effect on this script, why is the combination of SUID plus world-write still a critical finding?**
The danger stems from the world-write (`o+w`) permission combined with the intent implied by the SUID bit. A world-writable script means any standard user on the system can alter its contents. The SUID bit, while functionally ignored by the kernel, strongly indicates to an attacker that this script is meant to perform privileged operations and is likely executed by a highly privileged user or automation tool.

**3. What would make this scenario exploitable in practice?**
This scenario becomes immediately exploitable if a privileged process executes the script. As noted in the system audit, this specific `deploy.sh` script is executed by a root-owned cron job. Because the file is world-writable, a low-privileged attacker can simply append a malicious payload (such as a reverse shell or a command to add a new root user) to the file. When the root cron job triggers on its schedule, it will blindly execute the attacker's payload with full root privileges, resulting in total system compromise.
