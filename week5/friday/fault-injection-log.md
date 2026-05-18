# Fault injection log — kijanikiosk-payments pipeline

All faults were introduced on the `feature/week5-ci-pipeline` branch,
observed in Jenkins, then reverted to restore the pipeline to green.

| Stage faulted | How fault was introduced | Stages that ran | Stages that skipped | Design rationale |
|---|---|---|---|---|
| Lint | Added `console.log(undeclaredVar)` to `src/payments.js` | Lint | Build, Verify, Archive, Publish | Lint runs first so code style and syntax errors are caught before any build work begins, keeping the feedback loop as short as possible. |
| Build | Removed `mkdir -p dist` from the build script, causing the copy to fail | Lint, Build | Verify, Archive, Publish | A failed build means no artifact was produced; running tests against an artifact that does not exist would produce meaningless results. |
| Test | Changed `expect(calculateFee(1000)).toBe(25)` to `.toBe(999)` | Lint, Build, Verify (Test failed, Security Audit ran) | Archive, Publish | Failing tests block artifact creation — an artifact whose correctness has not been confirmed must never reach the registry. |
| Archive | Changed artifact glob to `*.xyz` so no file matched | Lint, Build, Verify, Archive | Publish | An artifact that cannot be located cannot be versioned or delivered; the Publish stage would have nothing to act on and would produce a misleading success. |
| Publish | Set `NEXUS_URL` to `http://localhost:9999` (unreachable port) | Lint, Build, Verify, Archive, Publish (failed) | — | All quality gates passed; only delivery failed. The verified artifact remains in Jenkins and can be republished by fixing the URL without re-running the full pipeline. |