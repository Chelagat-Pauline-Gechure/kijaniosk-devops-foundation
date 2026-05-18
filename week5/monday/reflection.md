# Week 5 Monday Reflection
**Repository:** KijaniKiosk DevOps  
**Path:** week5/monday/reflection.md

---

## Question 1: What Today's Pipeline Does Not Do

Today's pipeline has one stage — `Environment Check` — which confirms the Node.js
runtime is available and prints the last commit message. Tendo is right that this is not CI.
Under the three-property definition, two properties are entirely missing.

**Automated Verification** is the critical gap. The pipeline never calls `npm install` or
`npm test`, so there is no quality gate. Any broken code pushed to `main` would pass this
pipeline without complaint. To fix this, a `Test` stage must be added:

```groovy
stage('Test') {
  steps {
    sh 'npm install'
    sh 'npm test'
  }
}
```

When `npm test` exits with a non-zero code, Jenkins marks the stage failed and the
pipeline stops — nothing downstream runs.

**Immediate Feedback** is also incomplete. There is no `post { failure { } }` block to
notify the developer who pushed the breaking commit. Adding one closes the loop:

```groovy
post {
  failure {
    mail to: 'team@kijanikiosk.com',
         subject: "Build failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
         body: "Check the logs: ${env.BUILD_URL}"
  }
}
```

**Frequent Integration** is a team discipline rather than a pipeline stage, but today's
pipeline at least enforces that every push to `main` triggers a run — the foundation is
correct. Without `npm test` and a failure notification, what runs is a trigger with a
health check, not CI.

---

## Question 2: The Broken-Build Contract in Practice

**Realistic exception argument:** During this week's setup, I pushed a Jenkinsfile that
triggered a real pipeline failure — `libatomic.so.1: cannot open shared object file` —
caused by Node.js v26 requiring a system library missing from the Jenkins Docker
container. A developer in that situation might argue: "This is an environment issue, not
a code issue. My code is correct. I should be allowed to keep merging while someone
fixes the container." The argument sounds reasonable because the failure is
infrastructure, not application logic.

**Why the exception is more costly than it appears:** The moment `main` is red, every
other developer on the four-person KijaniKiosk team is in the same position — they
cannot trust whether their own changes pass or whether they are inheriting the
infrastructure failure. Kofi cannot merge his completed bug-fix. Ben cannot verify his
feature against a known-good base. If two more developers each make one "just this
once" exception during the two-week sprint, the team normalises a broken `main`.
By week two, nobody treats the red pipeline as urgent — the signal is noise. When a
genuine regression appears in the payments service three days before the board
review, it is invisible. The actual cost of the first exception is not the 20 minutes it
saves the one developer; it is the compounded distrust in the pipeline signal across
the entire team for the rest of the sprint.

---

## Question 3: The Jenkinsfile in the Repository

**Problem 1 — Server rebuild destroys the pipeline definition.** This week I ran Jenkins
in Docker using a `docker-compose.yml` with a named volume for `jenkins_home`. If
that volume is lost — a disk failure, an accidental `docker volume rm`, or a migration to
a new host — every pipeline configured only through the Jenkins UI is gone. There is
no `git log` to show what stages existed, no diff to review what changed, and no way
to restore it without rebuilding from memory. A Jenkinsfile in the repository means
`git clone` followed by pointing Jenkins at the repo fully restores the pipeline
definition. The pipeline is as recoverable as the codebase itself.

**Problem 2 — Pipeline changes bypass code review.** When the pipeline lives only
in the Jenkins UI, any admin can remove the `npm test` stage, add a direct deploy to
production, or change environment variables — without a pull request, without a
reviewer, and without a record in version history. A Jenkinsfile goes through the same
PR process as application code. A reviewer can question why the test stage was
removed before it merges. `git log Jenkinsfile` shows every pipeline change with
author, timestamp, and commit message. A UI-only pipeline has none of this: it cannot
be audited, reviewed, or recovered.

---

## Question 4: Webhooks vs Polling

**The trigger I used — webhook.** My build log shows `Started by GitHub push by
Chelagat-Pauline-Gechure`, which confirms the webhook was active. The mechanism
works like this: when I pushed the Jenkinsfile to GitHub, GitHub's servers sent an HTTP
POST request to `http://<jenkins-ip>:8080/github-webhook/` with a JSON payload
containing the branch, commit SHA, and author. Jenkins received the request, matched
it to the `kijanikiosk-payments` job configured with "GitHub hook trigger for GITScm
polling", and queued the build within seconds. No polling interval, no wasted API
calls — the push itself is the notification.

**When SCM polling would be more appropriate:** If Jenkins were running on a local
VM or behind a corporate firewall without a public IP, GitHub's servers cannot reach
the webhook endpoint. In that case, SCM polling (`H/5 * * * *`) is the correct fallback —
Jenkins initiates the check outward, so no inbound connectivity is required. During
this week's setup, if my Docker container had been running on a laptop without a
public IP, polling would have been the only viable option.

**Where the latency becomes a real problem:** With four developers each pushing
two or three times a day, a 5-minute polling delay is acceptable — the feedback still
arrives before they have moved far into the next task. But with ten or more developers
each integrating multiple times daily (the goal of genuine CI), 5 minutes is enough
time to start a new piece of work entirely. When the failure notification arrives, the
developer has lost the context of the change that caused it. At that team size and
push frequency, webhook-triggered feedback under 30 seconds is not a convenience
— it is the difference between a 2-minute fix and a 30-minute context switch.