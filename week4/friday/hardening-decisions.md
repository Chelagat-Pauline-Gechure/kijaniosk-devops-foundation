# KijaniKiosk Staging Environment — Security Decisions

*Prepared for Nia Okonkwo, Operations Lead*
*Week 4 — Infrastructure as Code Pipeline*

## What Was Built

This week, the KijaniKiosk staging environment moved from a single manually configured
server to a three-server system that can be rebuilt from scratch in under ten minutes by
any engineer on the team. The infrastructure is now a set of files stored in version control,
reviewed like code, and applied through an automated pipeline. This document explains the
security decisions made during that process in plain terms.

## Security Controls

| Control | What it does | Risk mitigated |
|---------|-------------|----------------|
| SSH access restricted to one IP address | Only the IP address of the engineer running the pipeline can connect to the servers over SSH. All other connection attempts are rejected before they reach the server. | Prevents unauthorised access to the servers from the internet. An exposed server with unrestricted SSH access is one of the most common entry points for attackers. |
| Remote state storage with access controls | The record of what infrastructure exists is stored in a locked, encrypted storage location rather than on a single engineer's laptop. Only team members with the correct credentials can read or change it. | Prevents accidental infrastructure changes from an outdated record. If the record lives on one laptop and that laptop is lost, the team loses the ability to manage the infrastructure safely. |
| State locking during changes | When one engineer is making infrastructure changes, the system prevents any other engineer from making changes at the same time. | Prevents two engineers from applying conflicting changes simultaneously, which can corrupt the infrastructure record and leave servers in an unknown state. |
| Encrypted state storage | The infrastructure record is stored with encryption at rest. | The record contains sensitive information including private network addresses. Encryption ensures that access to the storage location alone is not sufficient to read this information. |
| SSH key authentication only | Servers are configured to accept connections only from engineers who hold the correct private key file. Password-based login is disabled by default on the server image used. | Password-based login is vulnerable to automated guessing attacks. Key-based authentication requires physical possession of the key file, which cannot be guessed. |
| Firewall default deny | All incoming network connections to each server are blocked by default. Only the specific connections the server needs to function are explicitly opened. | Reduces the attack surface of each server to the minimum required. Any service that starts unexpectedly on an unusual port is automatically unreachable from the network. |
| Service accounts with no login shell | Each application runs as a dedicated system account that cannot be used to log into the server interactively. | If an attacker exploits a vulnerability in the application, they gain access only as that restricted account and cannot use it to move to other parts of the system. |
| Systemd service isolation directives | Each application service is configured with restrictions that prevent it from accessing parts of the operating system it does not need: it cannot write outside its own directories, cannot gain new privileges, and runs in a private temporary space. | Limits the damage an attacker can do if they compromise the application. A compromised service cannot read other services' files or escalate its own permissions. |

## How the Pipeline Protects Against Human Error

Before this week, provisioning a server required an engineer to remember every step,
execute them in the correct order, and verify the result manually. One forgotten step or
mistyped command could leave a server in a state that looked correct but was not.

The pipeline changes this in two ways. First, the infrastructure specification is written
down and reviewed before anything is applied. A second engineer can read exactly what
will be created before it happens. Second, the system proves its own correctness by
running twice. The second run of both the infrastructure and configuration tools must
show zero changes — meaning the result matches the specification exactly. If the second
run shows any differences, something is wrong and the pipeline does not pass.

## What the Current Security Posture Does Not Protect Against

This configuration is a correct starting point but it has gaps that a production
environment would need to address.

The servers do not yet run application code. The systemd service units are configured and
enabled, but the application binaries they reference do not exist on the servers. The
firewall and service isolation controls are in place, but there is nothing running on the
application ports yet. This will be addressed when application deployment is introduced.

The SSH access restriction is tied to a single IP address. If the engineer working from a
different location — a different office, a home network, or while travelling — their IP
address changes and they lose access. A more robust solution would route all
administrative access through a fixed, dedicated access point rather than relying on
individual IP addresses.

The state storage bucket and the servers themselves do not yet have audit logging enabled.
There is currently no record of who accessed the infrastructure record, when, or what they
changed. In a production environment, this audit trail is required for both security
monitoring and compliance purposes.

Finally, the current setup uses a single region with no backup arrangement. If the cloud
provider's infrastructure in that region becomes unavailable, the staging environment is
unavailable with it. For a production environment handling payments, a multi-region
arrangement would be required.