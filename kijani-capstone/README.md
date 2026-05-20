# KijaniKiosk Capstone — Track A: Infrastructure-First

## What is this?

KijaniKiosk is a payments and API platform. This capstone extends the existing
Kubernetes deployment into a multi-environment, production-approaching system.
The specific gap addressed: kk-payments had no staging environment, meaning
engineers tested changes directly against the production namespace with no
isolation and no automated rollback on health check failure.

This repository provisions an isolated kijani-staging namespace using Terraform,
configures it with environment-specific values using Ansible, and deploys
kk-payments through a Jenkins pipeline that runs a smoke test before offering
a production approval gate.

## Architecture

    Jenkins Pipeline
    Checkout -> Deploy Staging -> Smoke Test -> Approve -> Prod Deploy
         |                                                      |
         | terraform apply + ansible-playbook                   | kubectl apply
         v                                                      v
    kijani-staging namespace                        kijani-project namespace
    kk-payments x3 replicas                         kk-payments x3 replicas
    ConfigMap: DB_HOST=postgres-staging-service     ConfigMap: DB_HOST=postgres-service
    ConfigMap: NODE_ENV=staging                     ConfigMap: NODE_ENV=production

    Same Deployment manifest applied to both namespaces.
    Different ConfigMap per environment.

    Prometheus alert rules in monitoring/alerts.yml fire when:
    - kk-payments error rate > 5% for 2 minutes
    - kk-payments pod restarts > 2 in 10 minutes (staging)

Components:
- Terraform: provisions kijani-staging namespace with environment and managed-by labels
- Ansible: applies staging ConfigMap, secret, deployment, and service
- Jenkins: orchestrates the full pipeline with smoke test and approval gate
- Kubernetes: runs kk-payments in both staging and production namespaces
- Prometheus alerts: committed to monitoring/alerts.yml

## Prerequisites

Install these before running setup commands:

- Minikube v1.32+  https://minikube.sigs.k8s.io/docs/start/
- kubectl v1.28+   https://kubernetes.io/docs/tasks/tools/
- Terraform v1.5+  https://developer.hashicorp.com/terraform/install
- Ansible v2.15+   sudo apt install ansible
- Python kubernetes library: pip3 install kubernetes --break-system-packages
- ansible kubernetes.core collection v6.0+: ansible-galaxy collection install kubernetes.core
- Java v11+ (required for Jenkins agent): sudo apt install openjdk-11-jdk
- Docker v24+: https://docs.docker.com/engine/install/

## Setup

Run these commands in order from a clean checkout:

    # 1. Start Minikube
    minikube start
    minikube addons enable ingress

    # 2. Clone the repository
    git clone https://github.com/Chelagat-Pauline-Gechure/kijaniosk-devops-foundation
    cd kijaniosk-devops-foundation/kijani-capstone

    # 3. Install Python dependency for Ansible
    pip3 install kubernetes --break-system-packages

    # 4. Provision the staging namespace with Terraform
    cd terraform
    terraform init
    terraform apply -auto-approve
    cd ..

    # 5. If kijani-staging already exists in the cluster but not in state:
    #    cd terraform && terraform import kubernetes_namespace.staging kijani-staging && cd ..

    # 6. Configure staging with Ansible
    ansible-playbook ansible/playbook.yml -i ansible/inventory/localhost.ini

    # 7. Verify staging is running
    kubectl get pods -n kijani-staging
    # Expected: 3 pods with STATUS Running

## How to run the pipeline

    # The pipeline is triggered by any push to the repository.
    # To trigger manually:
    # 1. Open Jenkins at http://localhost:8080
    # 2. Open the kijani-capstone job
    # 3. Click Build Now
    #
    # Pipeline stages:
    # Checkout        - clones the repository
    # Deploy Staging  - runs terraform apply + ansible-playbook
    # Smoke Test      - kubectl rollout status + wget health check on port 80
    # Approve         - manual gate: enter reason and click Deploy to Production
    # Deploy Prod     - kubectl apply to kijani-project namespace + rollout status

## How to verify it works

    # Verify staging namespace has correct labels
    kubectl describe namespace kijani-staging | grep -E "environment|managed-by"
    # Expected: environment=staging, managed-by=terraform

    # Verify staging has different DB_HOST from production
    kubectl get configmap kk-payments-config -n kijani-staging -o jsonpath='{.data.DB_HOST}'
    # Expected: postgres-staging-service

    kubectl get configmap kk-payments-config -n kijani-project -o jsonpath='{.data.DB_HOST}'
    # Expected: postgres-service

    # Verify kk-payments running in both namespaces
    kubectl get pods -n kijani-staging
    kubectl get pods -n kijani-project
    # Expected: 3/3 Running in each namespace

    # Run smoke test manually
    PAYMENTS_POD=$(kubectl get pod -n kijani-staging -l app=kk-payments -o jsonpath="{.items[0].metadata.name}")
    kubectl exec $PAYMENTS_POD -n kijani-staging -- wget -qO- http://localhost:80/
    # Expected: nginx HTML response (200 OK)

## Known limitations

- No remote Terraform state backend: state is stored locally in the Jenkins agent
  workspace. Concurrent pipeline runs could corrupt state. Production fix: configure
  S3 backend with DynamoDB locking (same pattern as Week 4).

- Secrets not managed by a secrets manager: kk-payments-secrets is created with
  hardcoded placeholder values. Production fix: use Vault or Kubernetes External
  Secrets Operator to inject real values at deploy time.

- Prometheus alerts require Prometheus installation: monitoring/alerts.yml contains
  the alert rules but Prometheus is not installed in this local setup. Production
  fix: deploy kube-prometheus-stack via Helm and apply the alert rules.

- nginx:alpine used instead of real kk-payments image: the deployment uses nginx
  as a stand-in for the actual payments service. Production fix: build and push
  the real kk-payments image and update the image field in the deployment manifest.

- Jenkins runs on local Docker with a manually configured host-agent: the pipeline
  depends on SSH access to the host machine. Production fix: use a cloud-hosted
  Jenkins instance or migrate to GitHub Actions with a self-hosted runner.
