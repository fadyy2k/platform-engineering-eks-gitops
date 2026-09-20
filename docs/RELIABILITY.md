# Reliability Engineering

Phase 4 adds measurable service objectives, disruption controls, autoscaling, recovery exercises, and operator runbooks without pretending that a live EKS environment exists when this repository has not provisioned one.

## Availability SLO

The demo service target is **99.5% successful HTTP responses** over the service review window. The application exports two explicit counters:

```text
platform_demo_http_requests_total{code="2xx"}
platform_demo_http_requests_total{code="5xx"}
```

Prometheus records request rate, error rate, and 5-minute availability. Two multi-window burn alerts protect the error budget:

| Alert | Windows | Burn multiple | Error ratio threshold | Severity |
| --- | --- | ---: | ---: | --- |
| Fast burn | 5m + 1h | 14.4x | 7.2% | critical |
| Slow burn | 30m + 6h | 6x | 3.0% | warning |

The thresholds are derived from the 0.5% error budget rather than chosen as arbitrary CPU or pod-count alarms.

## Workload resilience

`platform-demo` now has:

- two baseline replicas
- `PodDisruptionBudget` with `minAvailable: 1`
- hostname topology spreading
- rolling updates with `maxUnavailable: 0`
- readiness and liveness probes
- CPU/memory requests and limits
- HPA from 2 to 6 replicas at 70% average CPU
- metrics-server deployed by Argo CD for HPA resource metrics

This protects the workload from routine node drains and gives it a bounded scale-out path. HPA is not a substitute for node autoscaling; the node-scaling decision is documented separately in [ADR-001](adr/001-node-autoscaling.md).

## Monitoring ownership

Argo CD manages a pinned `kube-prometheus-stack` chart. Prometheus is configured to discover `ServiceMonitor` and `PrometheusRule` resources outside the monitoring namespace. The demo workload exposes `/metrics`, and the reliability Application owns the ServiceMonitor, rules, PDB, HPA, and Alertmanager routing object.

Alertmanager routes by severity now, but the repository intentionally does **not** contain a company webhook, PagerDuty key, Slack URL, Teams URL, or SIEM endpoint. The default/critical receivers are sinks until an organization-specific secret-backed receiver is added. This prevents a public reference repository from embedding an operational destination.

## Recovery verification

`scripts/backup-restore-smoke.sh` is an executable Velero recovery test. It creates a unique marker ConfigMap, backs up the namespace, deletes the marker, restores the backup, and verifies exact marker recovery.

The script defaults to dry-run and requires `EXECUTE=1`. It is deliberately not run in GitHub-hosted CI because there is no live cluster or approved backup storage location attached to this public repository.

A production platform should run the recovery smoke test on a schedule against an isolated recovery namespace/account and record recovery time and recovery point objectives.

## Game days

`scripts/game-day.sh` supports two bounded scenarios:

- `pod-failure` — deletes one workload pod and verifies Deployment recovery
- `error-burn` — enables a controlled 503 failure mode, generates traffic through a local port-forward, then restores the Deployment

Both scenarios are dry-run by default. Production execution is blocked unless `ALLOW_PROD=1` is set explicitly.

Example non-production use:

```bash
EXECUTE=1 ENVIRONMENT=dev ./scripts/game-day.sh pod-failure
EXECUTE=1 ENVIRONMENT=dev ./scripts/game-day.sh error-burn
```

The error-burn scenario exists specifically to exercise the SLO alerts instead of relying on synthetic Prometheus expressions only.

## What is and is not proven

CI proves configuration syntax, rule behavior, application metrics behavior, manifest schema, and script quality. It does **not** prove real EKS scheduling, AWS network behavior, Alertmanager delivery, node autoscaling, or backup storage durability. Those require a provisioned environment and are tracked as activation/operational evidence rather than being claimed by static code alone.
