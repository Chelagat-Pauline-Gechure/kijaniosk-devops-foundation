# Week 4 Wednesday - Reflection and Engineering Thinking

## Question 1: The Module Boundary Decision

The VM and security group were extracted into the `app_server` module because they share
a lifecycle — every app server needs exactly one security group, and they are always created
and destroyed together. The networking resources (VPC, subnets, internet gateway, route
tables) stayed in the root module because they have a different lifecycle: the network exists
before any VM is created and should persist even if all VMs are destroyed. Mixing them would
mean a developer could accidentally destroy the network by targeting the module.

Extracting networking into a separate module makes sense when the same network needs to
be shared across multiple projects or teams, or when the networking configuration is complex
enough to warrant its own versioned, tested component. The standard pattern is a
`networking` module that outputs VPC ID and subnet IDs, which the `app_server` module
then consumes as inputs.

The risk of combining network and VM resources in a single module is severe. If a developer
runs `terraform destroy -target module.app_servers`, Terraform would destroy both the
VMs and the network they run in. Any other resources connected to that network — databases,
load balancers, other VMs — would lose their network connectivity immediately. Keeping
network and compute in separate modules means the network can never be accidentally
destroyed by targeting a compute resource. The network is the foundation; it should be the
last thing destroyed and the first thing created.

## Question 2: for_each Removal Behaviour

When "cache" is added to the `locals.servers` map and `terraform plan` is run, Terraform
sees one new key in the map that has no corresponding resource in state. The plan shows
exactly one `+` create action for `module.app_servers["cache"].aws_instance.this` and
`module.app_servers["cache"].aws_security_group.app`. The existing three servers —
`api`, `payments`, `logs` — show zero changes because their keys are stable and unchanged
in the map. Applying the plan creates the cache server without touching anything else.

With `count`, Terraform addresses resources by numeric index: `aws_instance.this[0]`,
`aws_instance.this[1]`, `aws_instance.this[2]`. If the servers list is ordered as
`["api", "payments", "logs"]` and "payments" is removed, what was index `[2]` (logs)
becomes index `[1]`. Terraform sees index `[1]` changed and index `[2]` deleted, and plans
to destroy and recreate the logs server even though nothing about it changed. This causes
unnecessary downtime for a server that was not touched.

`for_each` uses stable string keys. Removing "payments" from the map only destroys the
payments instance — `module.app_servers["api"]` and `module.app_servers["logs"]` are
completely untouched because their keys did not change. For any collection where resources
have distinct identities (which is almost always the case with servers), `for_each` is the
correct choice. `count` should be reserved for truly anonymous, interchangeable resources
where the order and identity of individual elements does not matter.

## Question 3: State as a Team Artefact

When Tendo runs `terraform plan` at the same time Amina runs `terraform apply`, the
following happens: Amina's `apply` acquires a lock on the remote state file in S3, backed by
a DynamoDB entry. Tendo's `plan` also attempts to acquire the lock and fails immediately
with a lock error. Tendo's plan does not succeed while the lock is held.

The lock error output contains the following useful diagnostic information: the lock ID (a UUID
that uniquely identifies this lock), the path to the locked state file, the operation type
(`OperationTypeApply`), the identity of who holds the lock (`amina@kijanikiosk`), the
Terraform version they are running, and the timestamp when the lock was acquired. This tells
Tendo exactly who is running what and when they started, so he can decide whether to wait
or contact Amina.

If Amina's apply starts, provisions two of the three servers, and then crashes mid-run because
her laptop lost power, the recovery procedure is as follows. First, check the current state with
`terraform state list` to see which resources were successfully written before the crash.
Second, check whether a stale lock remains with `terraform plan` — if a lock error appears
and the locking process is confirmed dead, clear it with `terraform force-unlock LOCK_ID`
using the lock ID from the error output. Third, run `terraform plan` to see what Terraform
believes still needs to be created. Because Terraform writes each resource to state as it is
created, the two servers that were provisioned before the crash will be in state and will show
zero changes. Only the third server will show as needing creation. Fourth, run
`terraform apply` to complete the interrupted run. Never use `terraform force-unlock`
unless certain the locking process has died — using it while another apply is running will
corrupt the state file.

## Question 4: What Three Provisioned VMs Cannot Do

At the end of Wednesday, three VMs exist in state with correct networking and security
groups. But they are running default Ubuntu 22.04 with nothing installed, no application
users, no systemd units, no log rotation, and no application code. Terraform cannot configure
any of these things directly because of an architectural boundary: Terraform is an
infrastructure provisioning tool that operates at the API level of cloud providers. It creates and
manages cloud resources by making API calls. Installing packages, writing configuration
files, creating system users, and enabling services are operating system-level operations that
require a running shell session inside the VM, which is not something cloud provider APIs
expose.

To install nginx on one of these VMs using only Terraform, the `user_data` argument on
`aws_instance` could be used to pass a shell script that runs at first boot:

```hcl