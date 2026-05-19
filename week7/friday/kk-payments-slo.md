# kk-payments SLI and SLO Definitions

## Service: kk-payments (KijaniKiosk Payments API)
## Measurement window: 30-day rolling

---

## SLI 1: Availability

**What we measure:** The percentage of health-check requests to `/health` that return HTTP 200 within the 30-day window.

**Data source:** nginx access logs (`/var/log/nginx/access.log`), filtered to `/health` endpoint requests. Calculated as: `(total 200 responses / total requests) × 100`.

**Measurement window:** Evaluated over the trailing 30 days. Sampled every 5 seconds by the post-deploy-monitor.sh script during deployment windows.

**SLO target (proposed — not yet measured against production traffic):** 99.9% availability over any 30-day window.

---

## SLI 2: Latency

**What we measure:** The 95th percentile (p95) response time for all requests to the payments service, measured end-to-end from nginx receipt to response.

**Data source:** nginx access logs using the `$request_time` variable. Calculated as the p95 value over all requests in the trailing 30 days.

**Measurement window:** 30-day rolling window. Flagged when p95 exceeds threshold in any 5-minute sub-window.

**SLO target (proposed — not yet measured against production traffic):** p95 latency <= 500ms for 99% of 5-minute windows in the 30-day period.

---

## SLI 3: Payment Error Rate

**What we measure:** The percentage of payment requests that return a 5xx HTTP status code (server-side errors), excluding 4xx errors (client errors).

**Data source:** nginx access logs filtered to the `/payment` path, counting responses where status >= 500. Calculated as: `(5xx responses / total payment requests) × 100`.

**Measurement window:** Evaluated over the trailing 30 days.

**SLO target (proposed — not yet measured against production traffic):** Payment error rate <= 0.1% over any 30-day window.

---

## Rollback Threshold Table

| SLI | SLO Target (30-day) | Short-window rollback threshold | Relationship |
|-----|--------------------|---------------------------------|--------------|
| Availability | 99.9% | 3 consecutive health check failures (~15 seconds) | A burst of 3 failures in 15 seconds would consume ~0.004% of the monthly error budget — triggering early before the SLO is at risk |
| Latency | p95 <= 500ms | p95 > 1000ms in any 1-minute window | 2x the SLO threshold triggers rollback; latency degradation of this magnitude signals a systemic problem, not a transient spike |
| Payment error rate | <= 0.1% | > 1% in any 2-minute window | A 10x spike above the SLO target in a short window indicates a critical deployment defect; rollback before the budget is consumed |

---

## What We Do Not Commit To

**Upstream dependency availability:** kk-payments SLOs cover only the service layer we operate. We do not commit to availability of third-party payment processors (e.g. card network APIs) because their reliability is outside our control and cannot be improved by our deployment practices.

**Client-side latency:** We measure latency at the nginx layer. Network latency between nginx and the end user's device is not included in our p95 SLI because it varies by geography and is not affected by our deployment pipeline.
