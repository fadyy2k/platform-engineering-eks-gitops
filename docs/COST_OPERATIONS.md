# Cost and Right-Sizing Operations

Phase 5 adds **OpenCost** for cluster cost visibility and **VPA recommender-only mode** for evidence-based CPU/memory sizing. Neither component is allowed to mutate application resources automatically.

## OpenCost

OpenCost is managed by Argo CD and reads from the in-cluster Prometheus instance created by `kube-prometheus-stack`.

The repository also records a simple estimated monthly node run-rate:

```promql
sum(node_total_hourly_cost) * 730
```

The reference lab warning threshold is **USD 150/month**. This is a guardrail for the demo environment, not a universal budget recommendation. Change the threshold to match the environment's approved budget before production use.

## PlatformMonthlyRunRateHigh

When the estimated monthly node run-rate remains above the configured threshold for 30 minutes:

1. check whether a deployment or game day temporarily increased replicas
2. inspect node count, instance type, and utilization
3. compare HPA desired replicas with actual workload demand
4. inspect VPA recommendations before changing CPU/memory requests
5. identify idle or over-provisioned workloads
6. avoid lowering requests below observed safe bounds simply to silence the alert
7. document whether the corrective action is right-sizing, schedule reduction, node-shape change, or an approved budget increase

## VPA as a recommender only

The Vertical Pod Autoscaler is installed with:

- admission controller disabled
- updater disabled
- recommender enabled
- workload VPA `updateMode: Off`

This lets the platform collect recommendations without creating a feedback loop with the HPA.

Read the recommendation with:

```bash
./scripts/right-size-report.sh
```

A recommendation should be evaluated against latency, error budget, JVM/runtime behavior where relevant, and burst capacity before changing requests or limits.

## What cost data is not claimed

Static CI proves the charts and rule syntax. It does not prove an actual dollar amount because no live EKS billing/usage stream is attached to this public repository.
