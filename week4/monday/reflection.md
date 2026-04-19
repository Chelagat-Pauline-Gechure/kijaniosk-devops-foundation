# Week 4 Monday Reflection: Engineering Thinking

## Question 1: The Idempotency Gap
**The Mechanism:**
Terraform achieves idempotency through the **state file (`terraform.tfstate`)** . This file acts as a private map where Terraform records the unique AWS Instance IDs and security group attributes it has created. When `terraform apply` runs, it compares your code against this state file and the live AWS environment to calculate the minimal set of changes required.

**Divergence Scenario:**
Divergence happens through **Drift**, such as when a human manually terminates an instance in the AWS console without using Terraform. 
* **The Scenario:** The state file still thinks the VM exists, but the actual infrastructure is gone.
* **The Response:** Running `terraform plan` will detect that the resource is missing. Terraform will then propose a "Create" (+) action to restore the VM to the desired state .

## Question 2: Declarative Specification Quality
**Under-specified Gaps in my `desired-state-spec.md`:**
1. **AMI Selection Logic:** My spec mentions "Ubuntu 24.04", but it doesn't specify which specific AMI ID or "Image Family" to use. If Terraform assumed a default, it might pick a version with different pre-installed packages, leading to configuration errors in Ansible.
2. **Subnet Assignment:** I recorded the default subnet ID, but didn't specify the **Availability Zone (AZ)**. Terraform might choose `eu-west-1b` while our other infrastructure is in `eu-west-1a`, potentially increasing latency or cross-AZ data costs.

**The Relationship:**
The reliability of automation is only as good as the precision of the specification . High-quality specs ensure that the automation produces predictable results across any environment rather than relying on "correct by accident" defaults.

## Question 3: Tool Boundary
| Task | Best Tool | Why & Consequences of using the wrong tool |
| :--- | :--- | :--- |
| **1. Firewall Rule (Port 80)** | **Terraform** | This is a cloud-level resource. Using bash lacks drift detection; if someone deletes the rule, a script won't notice, but Terraform will catch it. |
| **2. Installing Nginx 1.24.0** | **Ansible** | This is "inside-the-box" configuration. Terraform is not designed for OS-level packages; using it for this requires brittle scripts that don't track state reliably. |
| **3. Verifying HTTP Response** | **Bash** | Verification is an imperative, one-time check. Terraform cannot "test" a URL, and Ansible is too heavy for a simple `curl` check. |

## Question 4: From Script to Spec
**Clean Translations:**
**Phase 5 (Firewall)** and **Phases 2-3 (Service Accounts/Directories)** translated cleanly into the spec. These describe "objects" that either exist or do not.

**Difficult Translations:**
**Phase 8 (Health Check)** and **Phase 1 (Package installation)** were harder to express as "desired state". A health check is a sequence of actions (Wait, Test, Record), which is easier to define as a bash script than a static specification.

**Nature of Provisioning vs. Management:**
This difficulty proves that **Infrastructure Provisioning** (Terraform) handles the "static" architecture, while **Configuration Management** (Ansible) and **Scripting** (Bash) handle the fluid lifecycle of the software.