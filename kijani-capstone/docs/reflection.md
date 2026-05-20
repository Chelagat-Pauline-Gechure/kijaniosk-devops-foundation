# Capstone Reflection

## What did you get wrong?

I underestimated the complexity of connecting Jenkins to the host machine.
My initial assumption was that Jenkins could run kubectl and terraform directly
because they were installed on my machine. I did not account for the fact that
Jenkins runs inside a Docker container with its own isolated filesystem, and
that none of the host tools are accessible from inside the container.

The decision I got wrong was not planning the agent setup before starting the
build. I spent significant time debugging terraform not found and kubectl not
found errors inside the pipeline before realising the root cause. I should have
verified tool availability inside the Jenkins container on day one before writing
a single Jenkinsfile stage.

With the knowledge I have now, I would start every pipeline project by running
docker exec jenkins which terraform and docker exec jenkins which kubectl before
writing any pipeline code. If the tools are missing, the agent architecture needs
to be resolved first. A pipeline that cannot run its own stages is not a pipeline.

## What is the most important thing you learned?

The most important thing I learned is that idempotency is not automatic — it has
to be designed in. This appeared in Week 4 when Terraform taught me that
infrastructure should be declarable and repeatable. I understood it conceptually
then, but the capstone made it concrete.

When Ansible ran successfully the first time but failed when Jenkins ran it as a
different user, I understood that idempotency requires thinking about every
execution context, not just the happy path. The fix — installing the Python
kubernetes library for jenkins-agent specifically, not just for my own user — was
a two-minute change, but finding it required understanding that the same playbook
can behave differently depending on who runs it.

What changed in how I think about software delivery: I now treat "works on my
machine" as the beginning of the problem, not the end of it.

## What would a second pass look like?

With two more weeks and everything I built as a starting point, I would make
three specific changes.

First, I would add a remote Terraform backend. The current setup stores state
locally in the Jenkins agent workspace, which means a fresh workspace loses all
state and the pipeline breaks. I would configure an S3 backend with DynamoDB
locking — the same pattern from Week 4 — so state persists across pipeline runs
without manual copying.

Second, I would replace the hardcoded secret values in the Ansible playbook with
Kubernetes External Secrets Operator pulling from a local Vault instance. The
current DB_PASSWORD and JWT_SECRET are placeholder strings committed in plain
sight. This is the most critical production gap — everything else is a reliability
or observability concern, but plaintext secrets in a playbook is a hard blocker
for any real deployment.

Third, I would install Prometheus and wire the alert rules in monitoring/alerts.yml
to a running instance. The alerts are committed and correct but never fire because
there is no Prometheus to evaluate them. Deploying kube-prometheus-stack via Helm
and applying the rules would complete the observability layer and turn the
monitoring directory from documentation into a working signal.
