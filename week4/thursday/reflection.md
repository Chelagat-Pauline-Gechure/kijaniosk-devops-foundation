# Week 4 Thursday - Reflection and Engineering Thinking

## Question 1: Ansible vs Bash Idempotency

Ansible achieves idempotency through its module system. Each module is designed to check
the current state of the system before making any change. The module compares what exists
against what the task declares, and only acts if there is a difference. No guard conditions
are needed in the playbook because the guard logic is built into every module.

When `ansible.builtin.user` runs with `state: present`, it queries the system's user
database (`/etc/passwd`) to check whether a user with that name already exists. If the user
exists and all declared attributes (group, shell, home directory) match, the task reports `ok`
and makes no changes. If the user exists but an attribute differs from what the task declares,
Ansible updates only that attribute and reports `changed`. If the user does not exist at all,
Ansible creates it and reports `changed`.

If `ansible.builtin.shell: useradd kk-api` were used instead, the shell module would
execute the `useradd` command unconditionally on every playbook run. The second run would
fail with an error because the user already exists and `useradd` does not handle that
gracefully. To make it idempotent, a guard condition like `id kk-api || useradd kk-api`
would be required — exactly the pattern that Ansible modules are designed to eliminate.

The shell module is generally the wrong choice for idempotent provisioning tasks because it
executes commands blindly without checking current state. It cannot report `ok` versus
`changed` accurately because it has no knowledge of whether the system changed as a
result of the command. Every run shows `changed` regardless of whether anything actually
changed, which makes the second-run idempotency proof impossible and breaks the
ability to detect real changes in a sea of false positives.

## Question 2: Handler Behaviour Under Parallel Execution

The handler runs **twice** in total — once on host A and once on host B. On host C the unit
file task reported `ok`, meaning nothing changed, so no notification was sent and the
handler does not run on that host. Handlers are per-host: each host manages its own
notification queue independently.

When two tasks on the same host both notify the same handler, the handler still runs only
**once** on that host. The rule is: a handler is deduplicated within a single play on a single
host. No matter how many tasks notify it, it runs at most once per play, at the end of the
play after all tasks have completed.

This rule prevents unnecessary service restarts when multiple configuration changes are
applied in the same playbook run. Without deduplication, deploying both the unit file and
the environment file in the same play would restart the service twice. With deduplication,
the service restarts once at the end, after all configuration files are in their final state.
This means the service always starts with a complete, consistent configuration rather than
being restarted mid-way through a set of changes.

## Question 3: The Terraform to Ansible Inventory Bridge

**Approach 1: Use Terraform state directly via terraform output**

After `terraform apply`, parse the outputs programmatically in a shell script. Extract each
IP using `terraform output -raw api_server_ip` and write them into `inventory.ini` before
calling `ansible-playbook`. This is the approach used in `pipeline.sh`. It is simple, requires
no additional tooling, and works with any cloud provider as long as Terraform outputs the
IPs. The tradeoff is that it only works when run from a machine with access to the Terraform
state backend and the AWS credentials. It is also a one-shot extraction: if the inventory file
is later used without re-running the pipeline, it may be stale.

**Approach 2: Use the cloud provider's API via dynamic inventory**

Ansible supports dynamic inventory scripts and plugins that query the cloud provider API
directly to discover running instances. The `aws_ec2` plugin queries the AWS EC2 API, finds
instances matching tag filters (e.g. `Environment=staging`), and generates the inventory
automatically at the moment `ansible-playbook` runs. The inventory is always current
because it reflects the live state of the cloud account, not a previously extracted snapshot.
The tradeoff is additional configuration complexity: the plugin requires cloud credentials
accessible to Ansible, tag discipline on all instances, and a `aws_ec2.yml` plugin
configuration file instead of a simple `inventory.ini`.

For the KijaniKiosk team of three engineers, the Terraform output approach in `pipeline.sh`
is the better recommendation at this stage. The team is already managing Terraform state
centrally with a remote backend. Extracting IPs from Terraform outputs keeps the inventory
generation within the same tool the team already understands, avoids introducing a new
dependency, and ensures the inventory reflects exactly what Terraform provisioned rather
than whatever the cloud API happens to return. As the team and infrastructure grows,
migrating to dynamic inventory becomes worthwhile.

## Question 4: Configuration Drift in the Ansible Model

In an Ansible-managed environment, drift detection happens at the task level on every
playbook run. Ansible does not maintain a separate state file like Terraform. Instead, when
the playbook runs, each module checks the actual current state of the system against the
declared desired state. If drift exists, the module reports `changed` and corrects it. If no
drift exists, the module reports `ok`.

If an engineer manually changes the UFW rules on the payments server, the next playbook
run will detect the difference when the UFW tasks execute. The tasks that manage the
affected rules will report `changed` and restore the declared firewall configuration,
overwriting the manual change. The drift is corrected silently as a normal part of playbook
execution.

Ansible's drift correction model differs from Terraform's in one important way: Ansible
corrects drift as a side effect of applying the playbook, while Terraform separates detection
from correction. Terraform's `terraform plan` shows drift explicitly before anything is
changed, giving the operator a chance to review and decide. Ansible applies and corrects
drift in the same operation without a separate review step.

What Ansible does not do that Terraform does is maintain a persistent record of what it
manages. Terraform's state file tracks every resource it owns, which means it can detect
resources that were deleted outside of Terraform and plan to recreate them. Ansible has no
equivalent: if a directory or user is deleted manually between playbook runs, Ansible will
recreate it on the next run, but there is no way to ask Ansible "what is the current drift
across all managed servers?" without actually running the playbook. The operational
implication for the KijaniKiosk team is that drift is only visible when the playbook is run.
Running the playbook regularly on a schedule — rather than only when making changes —
is the operational practice that compensates for the absence of a persistent state record.