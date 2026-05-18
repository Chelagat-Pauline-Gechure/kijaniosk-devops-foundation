# How KijaniKiosk protects every payment before it ships

**Prepared for:** Nia and the KijaniKiosk board
**Subject:** Automated quality enforcement on the payments service

---

## The problem this solves

Until this week, every change to the payments service was deployed by hand.
A developer would write code, run a few checks on their own laptop if they
remembered, and copy the result onto the server. This worked when one person
owned the process end to end. With four developers working across time zones,
it stopped working. Tests got skipped under deadline pressure. The wrong
version was deployed. A change pushed at midnight had no one watching for
failures until the next morning, by which time customers had already been
affected.

The system described in this document removes the human from the quality
enforcement step entirely. Every time a developer saves their work to the
shared codebase, an automated process checks whether the change meets our
standards before it is recorded as an approved version. No one can bypass
this check by accident or by choice.

---

## What happens between a developer saving code and a version reaching the registry

| Stage | What it does | What a failure here means |
|---|---|---|
| 1. Lint | Reads the code for formatting and syntax errors before anything is built | The code has errors a compiler would reject — stopped immediately |
| 2. Build | Packages the code into a deployable bundle | The code cannot be assembled — nothing to test or ship |
| 3. Test | Runs six automated checks against the fee calculations and payment validation logic | The payments logic does not behave correctly — blocked from registry |
| 4. Security audit | Scans all software the service depends on for known vulnerabilities | A dependency with a known high-severity flaw is present |
| 5. Archive | Creates a versioned, fingerprinted copy of the bundle | The exact file is locked to the commit that produced it |
| 6. Publish | Sends the versioned file to the secure registry | The approved version is available for deployment |

Every stage must pass before the next one starts. If stage 3 fails, stages
4, 5, and 6 do not run. Nothing reaches the registry unless all six stages
pass without error.

Each version in the registry carries a label combining the software version
number and the unique identifier of the code change that produced it — for
example, `1.0.0-a3f9c12`. This means any version in the registry can be
traced back to the exact change it came from, and any previous version can
be restored in minutes if a problem is discovered after deployment.

---

## What happens when something goes wrong

When a developer introduces a change that breaks any of the six checks,
the process stops at that point and the developer receives a notification
within seconds — before they have moved on to their next task. The earlier
a problem is caught, the cheaper it is to fix. A problem caught at the test
stage takes minutes to correct. The same problem found after deployment
takes hours, and may require a review with this board.

The team operates under one rule: when the automated process is failing,
fixing it is the highest priority for the developer who caused it. All other
work waits. This rule exists because every other developer on the team
cannot submit their own work against a broken baseline. A single exception
quickly compounds — within a two-week sprint, a team that tolerates broken
baselines stops trusting the signal entirely, and the protection disappears
in practice even though it exists on paper.

In the past month the payments service had one incident where tests were
skipped before a deployment. That incident led to this system. The
automated process makes skipping tests structurally impossible, not just
against policy.

---

## What this system does not yet do

This pipeline confirms that code is correct and packages it for release.
It does not yet move that package onto the servers automatically. The step
from the registry to a running server is still performed by hand by an
engineer. The next phase of this programme, beginning in two weeks, will
add automated deployment with the ability to roll back to a previous
registry version if a problem is detected after release. Until then, the
registry holds approved and tested versions that are ready to deploy
whenever the team chooses, with full traceability back to the code that
produced them.