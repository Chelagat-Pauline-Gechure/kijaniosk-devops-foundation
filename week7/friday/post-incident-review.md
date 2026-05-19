# Post-Incident Review: Week 5 Monday Morning Incident

## Section 1: Incident Summary

During a live investor walkthrough on Monday morning, the deployment pipeline was
triggered against the staging environment instead of an isolated demo environment,
causing 48 seconds of staging unavailability while Nia was presenting to investors.
The pipeline completed successfully from its own perspective — it deployed to the
environment it was configured to target — but that environment was the one being
actively demonstrated. Normal service was restored within 48 seconds when the error
was detected and the pipeline was halted.

---

## Section 2: Timeline

| Time | Event |
|------|-------|
| 09:00 (estimated +-5 min) | Nia begins investor walkthrough using the staging environment |
| 09:14 (estimated +-2 min) | Deployment pipeline triggered by a scheduled run or developer push |
| 09:15 (estimated +-1 min) | Pipeline begins deploying to kijanikiosk-api-staging, disrupting the live demo |
| 09:15-09:16 (estimated +-1 min) | nginx returns errors as the service restarts during deployment |
| 09:16 (estimated +-1 min) | Error detected — Nia or a team member notices the disruption |
| 09:16-09:17 (estimated +-30 sec) | Pipeline halted or deployment completes; service begins recovering |
| 09:17 (estimated +-1 min) | Staging returns to healthy state; walkthrough resumes or concludes |

Note: All timestamps are estimated from the course narrative. Exact times could not
be reconstructed from retained log files.

---

## Section 3: Root Cause

**Root cause reached through five iterations of why:**

1. Why did the pipeline disrupt the investor demo?
   Because the pipeline targeted the staging environment while it was being used for
   the demo.

2. Why was staging being used for the demo?
   Because there was no separate pipeline-isolated demo environment — staging was the
   only deployed environment available to show investors.

3. Why was there no demo environment?
   Because the environment configuration did not include a mechanism to lock an
   environment against pipeline writes during active use.

4. Why did the pipeline not check whether staging was in use?
   Because the pipeline had no awareness of environment state beyond whether the
   deployment target was reachable — there was no in-use flag, no lock file, and no
   pre-flight check for concurrent usage.

5. Why was there no pre-flight check for concurrent usage?
   Because the deployment pipeline was designed to deploy to whatever environment was
   specified without verifying whether a human was actively depending on it. The
   environment targeting was a static configuration, not a dynamic check.

**Structural finding:** The pipeline lacked an environment lock mechanism. Any pipeline
trigger — scheduled, manual, or webhook — could write to the staging environment
regardless of whether it was in active use, because there was no technical guard
between "environment is reachable" and "environment is safe to deploy to."

---

## Section 4: Contributing Factors

- No staging environment lock: the pipeline had no way to mark an environment as
  "in use — do not deploy."
- Shared environment for demos and development: staging served two incompatible
  purposes simultaneously — active development target and investor demonstration
  environment.
- No pre-deployment notification: there was no process requiring the team to announce
  a deployment before triggering the pipeline.
- No deployment window policy: deployments could be triggered at any time, including
  during business hours when demos are likely to occur.

---

## Section 5: What Went Well

- Fast recovery: the disruption lasted only 48 seconds. Once detected, the team
  resolved it quickly without requiring manual infrastructure repair.
- Limited blast radius: the incident affected only the staging environment. No
  production system or customer data was impacted.

---

## Section 6: Action Items

| # | Action | Owner | Description | Target |
|---|--------|-------|-------------|--------|
| 1 | Implement environment lock file | DevOps Engineer | Add a .deploy-lock mechanism to staging. Before any pipeline deployment begins, it checks for this file and exits with a non-zero code if found. A separate lock-env.sh and unlock-env.sh script manages the lock. | 1 week |
| 2 | Create a dedicated demo environment | Infrastructure Lead | Provision a third environment using the existing Terraform module, with a separate domain and no pipeline write access. The pipeline must have demo explicitly excluded from its valid deployment targets. | 2 weeks |
| 3 | Add deployment window enforcement | DevOps Engineer | Configure the pipeline to reject deployments to staging between 08:00 and 18:00 EAT on weekdays unless a FORCE_DEPLOY=true override is explicitly set by a team lead. Enforced in the pipeline script, not by a calendar process. | 1 week |

---

## Prevention Mechanisms

The environment lock (Action 1) directly prevents a recurrence of this exact incident.
The dedicated demo environment (Action 2) eliminates the root cause structurally by
making it architecturally impossible to target the demo environment with the deployment
pipeline. The deployment window policy (Action 3) adds a time-based guard as a
secondary layer.
