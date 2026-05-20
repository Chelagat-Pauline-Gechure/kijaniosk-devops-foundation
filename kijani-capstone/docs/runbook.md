# KijaniKiosk Capstone — Operational Runbook

## System Overview

Two namespaces on a local Minikube cluster:
- kijani-staging: staging environment, managed by Terraform and Ansible
- kijani-project: production environment

Both run kk-payments (3 replicas, nginx:alpine) with environment-specific ConfigMaps.

## Starting the System from Scratch

    minikube start
    cd kijani-capstone/terraform && terraform init && terraform apply -auto-approve
    cd .. && ansible-playbook ansible/playbook.yml -i ansible/inventory/localhost.ini
    kubectl get pods -n kijani-staging

## Triggering the Pipeline

    Open http://localhost:8080
    Click kijani-capstone -> Build Now
    Watch stages: Deploy Staging -> Smoke Test -> Approve -> Deploy Production
    At approval gate: enter reason and click Deploy to Production

## Checking System Health

    kubectl get pods -n kijani-staging
    kubectl get pods -n kijani-project
    kubectl get configmap kk-payments-config -n kijani-staging -o jsonpath='{.data.DB_HOST}'

## Rolling Back a Bad Deploy

    kubectl rollout undo deployment/kk-payments -n kijani-staging
    kubectl rollout status deployment/kk-payments -n kijani-staging
    kubectl get pods -n kijani-staging

## Common Issues

Problem: Ansible fails with kubernetes library not found
Fix: pip3 install kubernetes --break-system-packages

Problem: Terraform fails with namespace already exists
Fix: cd terraform && terraform import kubernetes_namespace.staging kijani-staging

Problem: Jenkins pipeline runs on wrong agent
Fix: Verify host-agent is online at Manage Jenkins -> Nodes

Problem: Pods stuck in CreateContainerConfigError
Fix: kubectl create secret generic kk-payments-secrets
     --from-literal=DB_PASSWORD=staging-password-123
     --from-literal=JWT_SECRET=staging-jwt-secret-456
     -n kijani-staging
