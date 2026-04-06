# Security Hardening Analysis: kk-api.service

**Initial Score vs Final Score**
* Score before hardening: (e.g., 9.6 UNSAFE)
* Score after initial 5 directives: (e.g., 3.8 OK)
* Final score after adding 2 extra directives: (e.g., 1.2 EXCELLENT)

**1. SystemCallFilter=@system-service**
* **What it prevents at the kernel level:** This directive uses seccomp-bpf to restrict the application's ability to make arbitrary system calls to the Linux kernel. The `@system-service` group is a predefined allow-list of standard system calls necessary for typical daemons, while aggressively blocking obscure or dangerous syscalls (like `kexec_load` or `ptrace`).
* **Attack technique blocked:** It defeats vulnerability exploitation chains that rely on executing unusual syscalls to spawn root shells, interact directly with kernel modules, or attach debuggers to other running processes. Even if an attacker gains Remote Code Execution (RCE) in the Node.js app, the kernel will kill the process if the attacker's payload attempts a restricted syscall.

**2. RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX**
* **What it prevents at the kernel level:** This limits the types of network sockets the process can create. `AF_INET`/`AF_INET6` allow standard IPv4/IPv6 networking, and `AF_UNIX` allows local socket communication. It explicitly denies the creation of raw sockets, packet sockets (`AF_PACKET`), or Bluetooth sockets.
* **Attack technique blocked:** It prevents a compromised service from being used as a network staging point for lateral movement or packet sniffing. Specifically, an attacker who compromises the API cannot create an `AF_PACKET` socket to sniff raw traffic on the host's network interfaces, nor can they spoof IP headers for DDoS reflection attacks.
