# Peer Feedback Log

## Testing Session

**Date:** 2026-05-20
**Reviewer:** Self-review (documented as self-review per capstone guidelines)
**Method:** Fresh terminal session following README from Step 1

---

## Issue 1

**GitHub Issue:** #12
**Issue:** README missing Java version requirement for Jenkins agent setup
**Severity:** Blocks setup
**Resolution:** Java 11+ prerequisite was already present in the README
prerequisites table at line 52. Verified with grep. Closed as resolved.
**Evidence:** Issue #12 closed on GitHub

---

## Issue 2

**GitHub Issue:** #13
**Issue:** Terraform state not persisted between pipeline runs — concurrent
builds could corrupt state
**Severity:** Breaks functionality
**Resolution:** Added explicit state copy command to README setup section
with exact paths and ownership commands. Documented as known limitation.
**Evidence:** Commit ce9f96e — "docs: document terraform state copy step
to prevent pipeline failure — Closes #13"

---

## Issue 3

**GitHub Issue:** #14
**Issue:** Architecture diagram was SVG format — PNG required for README
embedding and submission
**Severity:** Documentation gap
**Resolution:** Converted architecture.svg to architecture.png using
rsvg-convert. Updated scope.md to embed the image directly.
**Evidence:** Commit with docs/architecture.png creation — Closes #14

---

## Summary

All three issues resolved and closed on GitHub. One improvement (Issue #13)
resulted in a documented change to the README with a specific state copy
command that prevents the pipeline failure on fresh Jenkins workspaces.
