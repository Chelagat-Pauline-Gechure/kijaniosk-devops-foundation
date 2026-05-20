# Production Readiness Assessment

## 1. External Routing

The current Ingress routes all traffic over plain HTTP, meaning payment credentials
and sensitive transaction data transmitted through kk-payments are unencrypted and
vulnerable to interception. This is not acceptable for a production payment service.
To fix this, TLS must be terminated at the Ingress level. This requires adding a
cert-manager ClusterIssuer resource and the annotation
`cert-manager.io/cluster-issuer: letsencrypt-prod` to the Ingress manifest, along
with a `tls:` block referencing a Secret where the certificate will be stored.
Without this, the system cannot handle real payment credentials safely.

Beyond TLS, rate limiting is absent. The nginx Ingress controller supports rate
limiting via the annotation `nginx.ingress.kubernetes.io/limit-rps`, which caps
requests per second per source IP. Without it, the /payments endpoint is exposed
to brute-force and denial-of-service attacks. Authentication at the Ingress layer
is also missing — the annotation `nginx.ingress.kubernetes.io/auth-url` can
integrate an OAuth2 proxy to enforce identity checks before requests reach the
backend services.

## 2. Health Signalling

The current readiness probe uses `initialDelaySeconds: 5`, which assumes kk-payments
starts in under 5 seconds. A real Node.js payment service that must establish a
database connection pool and run migrations may take 15-30 seconds to become ready.
Setting `initialDelaySeconds` too low causes repeated probe failures during startup,
which delays the Pod reaching Ready state and can trigger unnecessary restarts.
A safer value would be `initialDelaySeconds: 20`.

The `failureThreshold: 3` with `periodSeconds: 10` means Kubernetes marks a Pod
unhealthy after just 30 seconds of failed probes. On a payment service under
temporary database load — such as connection pool exhaustion during an end-of-month
spike — a 30-second window is too short. Kubernetes could restart a Pod that is
mid-transaction, risking payment data inconsistency or duplicate charges. Raising
`failureThreshold` to 6 gives the service a full 60-second recovery window before
a restart is triggered.

## 3. Capacity

Three static replicas with manual scaling is not a satisfactory answer for
end-of-month load spikes. A Horizontal Pod Autoscaler (HPA) is needed, but three
things must be true before it is viable: metrics-server must be running in the
cluster to expose CPU and memory metrics; resource requests must be defined on the
container (they are — 100m CPU and 128Mi memory); and an HPA object must be
configured targeting the kk-payments Deployment with a CPU utilisation threshold.

If the HPA target CPU percentage is set too high (e.g. 90%), Pods run at near
capacity before scaling triggers. The result is latency spikes and potential dropped
transactions during the scale-out lag period — the cluster reacts too late.
If the target is set too low (e.g. 10%), the HPA over-provisions constantly,
spinning up unnecessary replicas even under normal load. The operational consequence
is wasted cluster resources and higher infrastructure cost with no reliability benefit.
A reasonable starting target for kk-payments is 60%, validated through load testing
against realistic end-of-month traffic patterns.
