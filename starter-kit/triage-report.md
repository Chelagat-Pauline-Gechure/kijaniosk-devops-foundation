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