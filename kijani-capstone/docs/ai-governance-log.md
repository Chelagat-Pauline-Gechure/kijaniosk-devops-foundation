# AI Governance Log

## Entry 1

**Date:** 2026-05-20

**Tool used:** Claude (Anthropic)

**Task description:** Generate the Ansible playbook to configure the kijani-staging namespace with environment-specific ConfigMap and deploy kk-payments.

**What was provided to the AI:** Request to write an Ansible playbook that applies a staging ConfigMap, creates a Kubernetes secret, deploys kk-payments, and waits for all replicas to be ready. Context included the namespace name (kijani-staging), the ConfigMap values (DB_HOST: postgres-staging-service), and the deployment manifest structure.

**What the AI produced:** A complete Ansible playbook using the kubernetes.core.k8s module with five tasks: apply ConfigMap, create secret, apply deployment, apply service, and wait for readiness using k8s_info with a retry loop.

**What it got right:** The task structure was correct. The kubernetes.core.k8s module syntax was accurate. The readiness wait logic using until/retries/delay was the right pattern for polling deployment status.

**What it got wrong:** The playbook did not include the Python kubernetes library as a prerequisite. When run as jenkins-agent, the playbook failed with "Failed to import the required Python library (kubernetes)". The AI assumed the library was already installed system-wide, which was incorrect for a fresh user account. Additionally, the initial retry count (12 retries x 10s = 120s) was insufficient for the jenkins-agent environment where the first run needed time to pull the image.

**What was changed before applying:** Added pip3 install kubernetes --break-system-packages as a prerequisite step in the README setup section. Increased retries from 12 to 18 to allow 180 seconds for image pull and pod startup. Added explicit ansible_python_interpreter documentation to the README prerequisites.

---

## Entry 2

**Date:** 2026-05-20

**Tool used:** Claude (Anthropic)

**Task description:** Generate Terraform configuration to provision a Kubernetes namespace on a local Minikube cluster using the hashicorp/kubernetes provider.

**What was provided to the AI:** Request to write Terraform files (main.tf, variables.tf, outputs.tf) that provision a kijani-staging namespace with environment=staging and managed-by=terraform labels, targeting a local Minikube cluster via kubeconfig.

**What the AI produced:** A three-file Terraform configuration using the hashicorp/kubernetes provider ~> 2.0, with a kubernetes_namespace resource, variable for namespace name, and two outputs.

**What it got right:** The provider configuration, resource syntax, and label structure were all correct. The config_context = "minikube" correctly targeted the local cluster. The outputs correctly referenced the resource attributes.

**What it got wrong:** The configuration had no handling for the case where the namespace already exists in the cluster but not in Terraform state. When Jenkins ran terraform apply in a fresh workspace, it attempted to create a namespace that already existed, causing "namespaces kijani-staging already exists" error. The AI did not suggest using terraform import or checking for pre-existing state as part of the pipeline setup. Additionally, the governance checklist control for state management was not addressed: the state file was local only with no remote backend, meaning concurrent pipeline runs could corrupt state.

**What was changed before applying:** Added a manual terraform import step to the README setup instructions for cases where the namespace pre-exists. Copied the local state file to the Jenkins agent workspace as a workaround. Documented remote backend (S3 or Terraform Cloud) as a known limitation in the README. Added state file path to .gitignore to prevent accidental commit of sensitive state data.
