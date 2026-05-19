# Deployment Strategy Analysis

## Scenario 1: The Overnight Batch Processor
**Strategy:** Rolling Deployment

Rolling deployment is the most appropriate strategy here because the 24-hour rollback 
window is acceptable — if v2.1.0 produces incorrect output, the batch can simply be 
re-run with the old version the following night. Since the worker VM receives no external 
traffic and the infrastructure budget is minimal, rolling deployment's key advantage — 
no duplicate infrastructure required — makes it the practical choice over blue/green.

## Scenario 2: The User-Facing Authentication Service
**Strategy:** Blue/Green Deployment

Blue/green is the only viable strategy because the JWT token structure change is not 
backwards-compatible — running v1.x and v2.0 simultaneously (as rolling or canary would) 
would cause authentication failures for any user whose requests are split across versions. 
The atomic traffic switch guarantees no mixed-version exposure, and rollback is 
milliseconds (switching the proxy back), satisfying the hard requirement of restoring 
service within 5 minutes if authentication failures exceed 1%.

## Scenario 3: The ML Recommendation Engine
**Strategy:** Canary Deployment

Canary deployment is the correct strategy because the team explicitly wants to measure 
the new model's real-world impact before fully committing, and they accept that some 
users will receive recommendations from different model versions simultaneously — exactly 
the intentional mixed-version exposure that canary is designed for.

**Data to collect during deployment:**
- Click-through rate (CTR) per model version
- p95 latency per model version
- Error rate per model version
- Compute resource usage per model version (given v3.0 uses more compute per request)

**Go/no-go signals per stage:**

| Stage | Traffic Split | Go Signal | No-Go Signal |
|-------|--------------|-----------|--------------|
| Initial canary | 90% v2.8 / 10% v3.0 | CTR improvement trending positive, p95 latency within SLO, error rate unchanged | Latency spike beyond SLO or error rate increase → abort, route 100% back to v2.8 |
| Mid rollout | 50% v2.8 / 50% v3.0 | CTR improvement measurable and statistically significant, latency and errors still within SLO | Any metric regression compared to v2.8 baseline → abort |
| Full rollout | 0% v2.8 / 100% v3.0 | All metrics stable at 100% traffic → decommission v2.8 | Rollback available at any point by routing 100% back to v2.8 |