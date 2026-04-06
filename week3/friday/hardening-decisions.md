# Infrastructure Security and Foundation Strategy

## Executive Summary
As KijaniKiosk continues to scale its operations, ensuring the integrity, availability, and confidentiality of our production environment is paramount. This document outlines the proactive security measures and foundational infrastructure decisions implemented during our recent server provisioning phase. Our goal is to create a robust, resilient system that protects our customers' sensitive data, specifically payment information, while providing our engineering teams with a stable platform for continuous deployment. By embracing a "defense-in-depth" methodology, we ensure that a failure in one area of our system does not result in a total compromise. 

## The Core Philosophy: Defense in Depth and Least Privilege
Our approach to securing the kiosk's backbone revolves around two primary concepts: Least Privilege and Defense in Depth. 

Least Privilege means that every user, application, and process on our servers is given only the exact permissions they need to perform their specific job—and absolutely nothing more. If an application only needs to read a configuration, it is actively blocked from modifying it. If a service does not need to connect to the public internet, its network access is severed. 

Defense in Depth involves layering multiple security controls so that if an attacker manages to bypass one barrier, they immediately encounter another. We do not rely solely on a firewall to keep bad actors out; we assume the perimeter might eventually be breached and ensure the interior is heavily compartmentalized.

## Application Sandboxing
Historically, applications running on a server had broad visibility into the underlying operating system. We have overhauled this model. Our applications, particularly the payment processing engine, now run inside strict digital sandboxes. They are blinded to the rest of the server. They cannot view other applications' memory, they cannot modify critical system components, and they are restricted from executing administrative tasks. This drastically reduces the "blast radius" of a potential cyberattack. If a malicious actor successfully exploits a vulnerability within our payment application, they will find themselves trapped inside an isolated container with no tools, no access to user accounts, and no way to alter the server's fundamental behavior.

## Network Traffic and Log Management
We have also tightened our network perimeter. The server now operates on a "default deny" posture. Every single piece of incoming network traffic is blocked and dropped unless we have explicitly written a rule to allow it. We have restricted management access so that our administrators can only connect from highly secured, internal monitoring networks. 

Furthermore, auditability is critical for compliance and incident response. We have structured our audit logs to ensure they are easily accessible to our monitoring tools but heavily protected from tampering. We also instituted automated rotation mechanisms, ensuring that long-term operation does not result in storage exhaustion, which could otherwise cause localized outages.

## Security Controls Overview

| Control | What it does | Risk mitigated |
| :--- | :--- | :--- |
| **Dedicated Service Identities** | Assigns unique, non-human accounts to each application. | Prevents an attacker from using one compromised app to control another. |
| **Strict Directory Permissions** | Locks down folder access based on exact job requirements. | Stops unauthorized modification of critical configurations and application code. |
| **Access Control Lists** | Creates granular sharing rules for audit trails without opening them to everyone. | Ensures logging systems can function without exposing data to unauthorized internal users. |
| **Default Deny Firewall** | Drops all network traffic unless explicitly approved by engineering. | Defends against automated internet scanning, brute force attacks, and unauthorized probes. |
| **Internal Loopback Isolation** | Forces backend services to communicate only over a hidden internal network. | Prevents external actors from directly attacking the payment processing engine from the internet. |
| **System Isolation (Sandboxing)** | Blinds the application to the host operating system and restricts administrative privileges. | Drastically limits the blast radius if an application vulnerability is successfully exploited. |
| **Automated Log Rotation** | Compresses and safely archives old audit trails on a predictable schedule. | Prevents catastrophic storage exhaustion and ensures continuous, uninterrupted service availability. |
| **Automated Health Checks** | Continuously verifies app responsiveness and saves the status to a restricted zone. | Enables rapid, automated incident response without exposing diagnostic tools to external threats. |

## Honest Gaps
While the foundational infrastructure is now highly secure and heavily isolated, it is important to acknowledge what these server-level controls do not protect against. Our current hardening does not mitigate application-layer vulnerabilities; if a developer accidentally introduces a flaw like a SQL injection or cross-site scripting bug into the application code itself, these server rules cannot fix it. Additionally, we currently lack specialized protection against large-scale Distributed Denial of Service (DDoS) attacks, which would require intervention at the cloud-provider level. Finally, we rely on the secure management of SSH keys by our administrators; if an authorized developer's laptop is compromised and their keys are stolen, the attacker would bypass our network perimeter controls entirely. We must continue to invest in code auditing and endpoint security to close these remaining gaps.