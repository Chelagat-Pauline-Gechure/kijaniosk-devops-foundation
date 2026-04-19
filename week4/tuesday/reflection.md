# Week 4 Tuesday - Reflection and Engineering Thinking

## Question 1: The State File as a System

Terraform knows about all the extra attributes because when `terraform apply` runs, it makes
API calls to AWS which returns the full resource object — including every attribute AWS assigned
(instance ID, private IP, availability zone, etc.). Terraform records the entire API response into
`terraform.tfstate`, not just the attributes declared in the configuration.

When `terraform destroy` runs, Terraform removes all managed resources and then empties the
state file. Running `terraform state list` after destroy returns nothing, as observed in the lab.

If the state file was deleted manually without destroying the infrastructure, the next
`terraform plan` would show all resources as needing to be created again, because Terraform
would think nothing exists. This would cause a conflict: AWS already has the resources but
Terraform has no record of them. The correct recovery procedure is `terraform import` — each
existing resource is imported into a new state file by providing its resource address and cloud
ID, for example:

```bash
terraform import aws_instance.kk_api i-0978b3d812c48ac79
```

## Question 2: The (known after apply) Values

Values marked `(known after apply)` cannot be determined at plan time because they depend
on decisions AWS makes at the moment of resource creation, not decisions defined in the
configuration.

Two specific examples from the lab plan output:

**`public_ip = (known after apply)`** — AWS assigns public IPs from a pool at launch time.
Until the instance actually starts, no IP exists to report. Terraform cannot know this value
in advance because it is AWS's decision, not ours.

**`availability_zone = (known after apply)`** — When no AZ is specified in the configuration,
AWS selects one automatically based on available capacity at that moment. Terraform has no
way to predict which AZ AWS will choose before the instance is created.

If an output value depends on a `(known after apply)` attribute — as both outputs in this lab
did (`instance_public_ip` and `ssh_command`) — Terraform shows the output as
`(known after apply)` during plan as well. The actual values only appear after apply completes.

## Question 3: Hardcoded vs Variable

The security group in the current configuration has `41.90.208.215/32` hardcoded as the SSH
ingress source. This is a problem for a shared team configuration for two reasons: first, every
team member has a different IP address, meaning only one person can SSH in; second, IP
addresses change when working from different locations, requiring a code change and a new
plan/apply cycle just to update access.

The solution is to declare a variable for allowed SSH CIDR blocks:

```hcl
variable "ssh_allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH into the API server"
  type        = list(string)
}
```

Then reference it in the security group ingress rule:

```hcl
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.ssh_allowed_cidr_blocks
}
```

Each engineer sets their own IP in their local `terraform.tfvars`. The correct type is
`list(string)` because multiple team members may need access simultaneously and CIDR
blocks are strings.

## Question 4: What Tuesday's Configuration Cannot Do

Looking at the current configuration, every value that would need to differ for a production
deployment versus staging:

- `instance_type` — production needs a larger size (e.g. `t3.small` vs `t2.micro`)
- `environment` tag — `production` vs `staging`
- `ssh_allowed_cidr_blocks` — different team members or a bastion host IP
- `vpc_id` / `subnet_id` — production should use a dedicated VPC, not the default VPC
- AMI ID — production should pin a specific tested AMI rather than using `most_recent = true`
- Number of instances — production needs multiple VMs for redundancy, staging needs one

With today's approach, handling production would mean either copying the entire directory and
maintaining two sets of `.tf` files in parallel, or manually swapping `terraform.tfvars` values
and hoping nothing gets mixed up. Both approaches break as soon as any structural difference
exists between environments. For example, if production needs 3 VMs and staging needs 1,
there is no way to express that with today's configuration — the resource block only creates one
instance and would have to be copied manually three times.

Wednesday's `for_each` and modules solve exactly this problem. The same configuration
becomes reusable across environments by parameterising the differences and extracting shared
structure into reusable modules, so nothing in the source code changes between environments —
only the variable values do.