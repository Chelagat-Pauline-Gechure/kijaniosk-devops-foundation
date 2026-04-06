# KijaniKiosk API Server - Triage Report

**Date:** 2026-04-01
**Investigated by:** Chela
**Server:** Pooh
**Incident start (approximate):** 2024-01-15 04:07:55

## Summary
The API latency and subsequent downtime are the result of the database service failing due to severe system memory starvation. A rogue process consumed available RAM, causing the database to exhaust its connection pool, timeout queries, and eventually crash completely.

## Process and Resource State
The system is under severe memory pressure. While the CPU usage remains normal, memory availability has been critically depleted. The kernel's `systemd-oomd` (Out-Of-Memory daemon) is active and repeatedly logging warnings about missing swap space and degraded memory performance. A rogue Python script was identified as the primary anomalous memory consumer hoarding RAM.

## Filesystem and Disk
Disk space is not the root cause of this incident. The primary root partition (`/`) is exceptionally healthy at 58% utilization. The `/var/log/kijanikiosk/` directory contains an unusually large amount of data (271MB), which appears to be a rotated or archived log file (e.g., `access.log.1`), as there are no active `.log` files exceeding 50MB.

## Log Analysis
Application errors began precisely at 04:07:55. The error frequency reveals a clear cascading failure: the top errors are `Query` timeouts, `Database` capacity warnings, and `ECONNREFUSED` events. System logs (`syslog`) confirm the memory starvation via continuous `systemd-oomd` alerts. The `auth.log` is completely clean, ruling out an SSH brute-force attack as a contributing factor.

## Network and Service State
The web and application layers are healthy, but the data layer is down. NGINX (port 80) and the Node.js API (port 3000) are actively listening. The NGINX HTTP response time is practically instantaneous (0.001048s), proving the web server is not the bottleneck. Crucially, port 543



### Engineering Reflection and Systems Thinking

**1. The `/proc` boundary**
* **What `/proc` is:** The `/proc` directory is a "pseudo-filesystem" (or virtual filesystem). It does not exist on your hard drive. Instead, it is an illusion created dynamically by the Linux kernel in RAM to expose its internal data structures, hardware information, and running process states to user-space tools.
* **Why it doesn't persist:** Because it resides entirely in memory, it vanishes the moment the machine powers off or reboots.
* **Nature of the data:** This tells us that the data we are querying with tools like `ps aux` or `top` is completely ephemeral and represents the live, real-time state of the kernel exactly at the millisecond the command is executed.

**2. Kernel space and process isolation**
* **Why a runaway process can't corrupt the kernel:** Modern operating systems use virtual memory. A user-space process is given a sandboxed, virtual memory address space. It literally has no mathematical way to address or point to the physical memory where the kernel or other applications reside.
* **The mechanism:** This boundary is enforced jointly by the operating system kernel and the hardware's CPU (specifically the Memory Management Unit, or MMU). 
* **Implications if it didn't exist:** If this boundary did not exist (like in older OS versions such as Windows 98 or classic Mac OS), any application with a memory leak or a bad pointer could overwrite kernel memory, instantly crashing the entire operating system with a fatal kernel panic or blue screen.

**3. The triage pipeline you built**
Let's break down the log analysis pipeline: `grep -E "ERROR|WARN" app.log | awk '{print $4}' | sort | uniq -c | sort -rn`.
* **`grep -E`**: Scans the file and filters it, passing only lines containing "ERROR" or "WARN" to the next tool.
* **`awk '{print $4}'`**: Takes those filtered lines, splits them by whitespace, and extracts only the 4th column (the error type), dropping the timestamps.
* **`sort`**: Alphabetizes those extracted error types. (This is required because `uniq` only counts adjacent identical lines).
* **`uniq -c`**: Compresses the sorted list, outputting a single line per error type alongside a numerical count (`-c`) of how many times it appeared.
* **`sort -rn`**: Takes the final counted list and sorts it numerically (`-n`) and in reverse (`-r`), bringing the most frequent errors to the top.
* **If we reversed components:** If we put `uniq -c` *before* the first `sort`, `uniq` would fail to count correctly, as it would only combine errors that happened on consecutive lines, resulting in scattered and inaccurate totals.

**4. Containers and the kernel**
* **Why the host sees container processes:** Unlike virtual machines (which run entirely separate guest operating systems and custom kernels), Docker containers share the single host Linux kernel. To the host kernel, a containerized app is just a normal Linux process.
* **What kind of isolation it provides:** Containers provide isolation using two Linux kernel features: **Namespaces** (which restrict what a process can *see*, like faking a root filesystem or isolating process IDs) and **cgroups** (which restrict what a process can *use*, capping CPU and memory). Because the host's root process runs outside these namespaces, it has global visibility into everything running on the kernel.

**5. Operational consequence (The Failure Cascade)**
Looking closely at the application log timestamps, the rogue memory consumption was not the root cause—it was a symptom. The actual failure cascade was:
1. **03:45**: The database connection pool begins to fill up (`Database connection pool at 85 capacity`).
2. **04:07**: The connection pool completely exhausts (`Connection pool exhausted queuing requests`). The database isn't dead yet, but it cannot accept new work.
3. **04:08**: Queries begin timing out because they are stuck in the queue. 
4. **04:09**: Because API requests are stacking up and waiting for the database, the Node.js worker processes are kept alive, holding onto data. This causes the massive memory bloat (`Memory usage at 87% consider restarting workers`). 
5. **06:22**: The extreme memory pressure and systemic timeouts eventually cause the database service to crash completely, resulting in the hard `ECONNREFUSED` errors. 

**Conclusion:** The root cause was poor database connection pooling/capacity limits, which triggered a backlog of queued requests, resulting in systemic memory starvation as a secondary symptom.