# Week 4 Monday Reflection: Engineering Thinking

## Question 1: The Idempotency Gap
**The Mechanism:**
Terraform achieves idempotency through the **state file (`terraform.tfstate`)**. This file acts as a private map where Terraform records the actual unique IDs and attributes of every resource it has created. When you run `terraform apply`, Terraform performs a three-way comparison between your code (Desired State), the state file, and the real-world infrastructure. If the code says "create a file" and the state file confirms "file XYZ already exists with the correct content," Terraform knows to do nothing.

**Divergence Scenario:**
Divergence occurs through **Drift**, which happens when a human makes an ad-hoc change directly in the cloud console . 
* **The Scenario:** If the state file tells Terraform the VM is there, but a human manually deleted it in the GCP console, the state is now "stale". 
* **The Response:** The correct response is to run `terraform plan`. Terraform will refresh its state, realize the resource is gone, and propose a "Create" (+) action to restore the infrastructure to the desired state.

## Question 2: Declarative Specification Quality
**Under-specified Gaps:**
1. **Network Subnetting:** My spec identifies the "default" VPC but fails to specify a particular **Subnet CIDR range**. If Terraform defaults to an arbitrary subnet, it may provision the VM in a network segment that lacks the necessary routing to our other services.
2. **Disk Performance/Encryption:** The spec lists a 10GB size but lacks the **Disk Type** (e.g., Balanced vs. SSD) and **Encryption Profile**. Terraform might default to a low-performance disk that cannot handle the KijaniKiosk API load, leading to production latency.

**The Relationship:**
The quality of the specification directly dictates the **reliability and predictability** of the automation . High-quality specs eliminate assumptions; whenever a tool like Terraform has to "fill in the gap" with a default, it introduces a risk that the environment will be inconsistent across different regions or providers.

## Question 3: Tool Boundary


1. **Creating a firewall rule:** **Terraform**. This is an infrastructure resource that exists outside the VM. If handled by bash, we lose drift detection; if someone deletes the rule, a script won't notice, but Terraform will.
2. **Installing Nginx 1.24.0:** **Ansible**. This is "inside-the-box" configuration. Terraform is not designed to manage software versions inside a OS; using it for this requires brittle "provisioner" blocks that don't track state reliably.
3. **Verifying HTTP response:** **Bash**. Verification is a one-time, imperative check. Terraform cannot "test" a URL, and Ansible is unnecessarily complex for a simple `curl` test that determines if a phase passed or failed

## Question 4: From Script to Spec
**Clean Translations:**
**Phase 5 (Firewall)** and **Phases 2-3 (Service Accounts/Directories)** translated cleanly. These are declarative by nature—they describe a state that should exist (e.g., "The user 'amina' should exist").

**Difficult Translations:**
**Phase 8 (Health Check)** and **Phase 1 (Package installation)** were difficult. A health check is inherently a **sequence of steps** (Wait -> Test -> Log) rather than a static state. 

**Nature of Provisioning vs. Management:**
This difficulty proves that **Infrastructure Provisioning** (Terraform) is meant for the "static" architecture—the clouds and networks—while **Configuration Management** (Ansible) and **Scripting** (Bash) are required to handle the "fluid" lifecycle and verification of the software running on that architecture.