# Capstone Scope Document

## Problem Statement

kk-payments currently deploys to a single environment (the kijani-project namespace
on a local Minikube cluster). There is no staging environment. Engineers testing
changes apply them directly against the production namespace with no isolation.
When a bad image tag is pushed, the rollout stalls in production and requires manual
intervention to roll back. There is no automated health validation before production
traffic is affected.

## Track

Track A: Infrastructure-First

## What I Will Build

- Staging namespace: a kijani-staging namespace provisioned by Terraform and
  configured by Ansible, isolated from the production kijani-project namespace
  with environment-specific ConfigMap values (DB_HOST: postgres-staging-service).

- Jenkins pipeline: a pipeline that deploys to staging automatically, runs a smoke
  test against the staging deployment, and only offers the production approval gate
  after the smoke test passes.

- Environment-specific ConfigMaps: kk-payments running in staging with a different
  DB_HOST from production, using the same Deployment manifest for both environments.

- Prometheus alert rules: at least one alert rule committed to the repository that
  fires on kk-payments error rate exceeding 5% for 2 minutes.

- Fault handling demonstration: a deliberate bad image tag introduced to staging
  to show the rolling update stalls while original pods continue serving traffic,
  followed by a rollback.

## What Is Out of Scope

- Real AWS infrastructure: the system runs entirely on a local Minikube cluster.
  Provisioning cloud VMs or cloud-hosted Kubernetes is out of scope because it
  requires paid cloud access not available in this environment.

- Prometheus installation and live alerting: the alert rules are committed to the
  repository but Prometheus is not installed. Wiring live alerting would require
  deploying kube-prometheus-stack which is a multi-hour setup outside the capstone
  scope.

- TLS termination and real domain routing: the Ingress runs without TLS. Adding
  cert-manager and real certificates is a production hardening step outside scope.

- Real kk-payments application image: the deployment uses nginx:alpine as a
  stand-in. Building and publishing the actual payments service image is out of
  scope as the capstone focus is the delivery infrastructure, not the application.

## Success Criteria

1. A push triggering the pipeline deploys to kijani-staging automatically without
   manual steps, confirmed by kubectl rollout status returning exit 0.

2. The production approval gate only appears after the smoke test passes, confirmed
   by the Jenkins pipeline log showing Smoke test passed before Input requested.

3. A deliberately introduced bad image tag causes the rolling update to stall in
   staging with original pods continuing to serve traffic, confirmed by kubectl get
   pods showing mixed Running and ImagePullBackOff states simultaneously.

## Architecture Diagram

![Architecture Diagram](docs/architecture.png)
