# Local Runtime Evidence

The AWS activation path remains intentionally unexecuted, but the platform now also has **real runtime evidence** from a disposable local Kubernetes environment. This closes the gap between static CI and cloud provisioning without implying that an EKS account exists.

## Runtime environment

Evidence below was captured on **22 September 2026** from:

- `kind` cluster `platform-local`;
- Kubernetes **v1.36.4**;
- Argo CD reconciliation;
- Kyverno admission enforcement;
- kube-prometheus-stack / Prometheus;
- Trivy Operator;
- Falco modern eBPF;
- VPA in recommendation-only mode;
- OpenCost connected to the in-cluster Prometheus service.

The sanitized command transcript is stored at [`docs/evidence/local-runtime-2026-09-22.txt`](evidence/local-runtime-2026-09-22.txt).

## GitOps reconciliation

Nine applications were **Healthy / Synced** during the capture:

| Argo application | Runtime state |
| --- | --- |
| `platform-demo` | Healthy / Synced |
| `platform-security-policies` | Healthy / Synced |
| `metrics-server` | Healthy / Synced |
| `vertical-pod-autoscaler` | Healthy / Synced |
| `opencost` | Healthy / Synced |
| `cost-controls` | Healthy / Synced |
| `cost-monitoring-resources` | Healthy / Synced |
| `reliability-resources` | Healthy / Synced |
| `reliability-monitoring-resources` | Healthy / Synced |

This is evidence from the local `kind` runtime. It is not evidence of Argo running in EKS.

## Signed-image and admission enforcement

The local namespace enforces the Kubernetes **restricted** Pod Security profile and the project Kyverno policies. Three server-side dry-run requests isolate the supply-chain controls:

1. the immutable project image `ghcr.io/fadyy2k/platform-demo@sha256:5fc1...89db` was **admitted**;
2. the mutable project tag `ghcr.io/fadyy2k/platform-demo:latest` was **denied** by `validate-platform-demo-images`;
3. a syntactically valid but unknown digest in the project repository was **denied** by `verify-platform-demo-signature` when the registry manifest/signature could not be verified.

The admitted digest is the same digest signed keylessly by the trusted GitHub Actions workflow identity.

## Prometheus, SLOs and error-budget behavior

Prometheus reported **14/14 active targets UP**, including both demo replicas:

```text
platform-demo scrape targets up=2/2
PlatformDemoFastErrorBudgetBurn health=ok
PlatformDemoSlowErrorBudgetBurn health=ok
PlatformDemoTargetDown health=ok
```

A controlled error-burn exercise injected **200 HTTP 503 responses** and the slow-burn alert was observed firing afterwards. The helper then removed `FAIL_MODE` and the Deployment returned to **2/2 ready replicas**.

![Prometheus local runtime query](assets/evidence/local-prometheus-platform-demo.png)

## Trivy Operator runtime reports

Trivy Operator was actively generating cluster reports during capture:

```text
vulnerabilityreports=6
configauditreports=51
exposedsecretreports=6
rbacassessmentreports=23
clustercompliancereports=4
```

The `platform-demo` image vulnerability reports for the pinned digest showed **0 critical / 0 high / 0 medium / 0 low** findings at capture time. A separate ReplicaSet configuration audit contained **one medium finding**; the evidence records it rather than presenting a misleading all-green security story.

This is in-cluster Trivy Operator evidence, distinct from the build-time Trivy image gate in GitHub Actions.

## Falco runtime detection

A temporary BusyBox pod was created in the default namespace for a benign runtime probe. Falco produced a Kubernetes-attributed **Critical** event:

```text
rule=Drop and execute new binary in container
namespace=default
pod=falco-proof
image=docker.io/library/busybox:1.36
```

The temporary probe pod was deleted immediately after the test. This proves the syscall runtime sensor is producing Kubernetes-attributed detections in the local cluster.

## Recovery game days

Both controlled dev scenarios were executed with `EXECUTE=1` against the local cluster:

- **pod failure:** one demo pod was deleted and the Deployment recovered;
- **error burn:** the application returned 200 synthetic HTTP 503 responses, then the helper restored normal configuration and the Deployment converged to **2/2**.

At capture time the resilience objects also showed:

```text
PodDisruptionBudget minAvailable=1 disruptionsAllowed=1
HPA min=2 max=6 current=2 desired=2
```

The exercises did not touch AWS or production.

## Velero backup and restore drill

A fresh namespace-scoped backup was written to the lab's MinIO-backed Velero storage, then restored with a namespace mapping into a temporary proof namespace.

```text
backup phase=Completed
restore phase=Completed
restored Deployment ready=2/2
```

The restored namespace contained the Deployment, Service, PDB, HPA and VPA objects and was deleted after validation. This proves the recovery path in the local runtime; it does **not** prove AWS object-storage or EKS recovery behavior.

## VPA recommendation-only evidence

The VPA remains non-mutating and produced a measured recommendation:

```text
updateMode=Off
target=25m CPU / 250Mi memory
lower=25m CPU / 250Mi memory
upper=146m CPU / 250Mi memory
```

The recommendation is evidence to review, not an automatic resize.

## OpenCost local allocation

OpenCost successfully queried the in-cluster Prometheus service and returned live namespace allocation data. One 10-minute capture included:

```text
platform-demo totalCost=0.00043000 cpuCost=0.00037000 ramCost=0.00006000
monitoring    totalCost=0.00084000 cpuCost=0.00057000 ramCost=0.00027000
opencost      totalCost=0.00013000 cpuCost=0.00007000 ramCost=0.00005000
```

![OpenCost local runtime](assets/evidence/local-opencost.png)

!!! warning "Pricing boundary"
    The `kind` cluster has no AWS cloud-provider pricing identity. OpenCost's local/default model proves allocation plumbing and efficiency calculations, but these values are **not AWS spend or an AWS bill**.

## Reproduce the read-only checks

With the local stack already running:

```bash
./scripts/local-runtime-verify.sh
```

The helper refuses non-`kind` contexts by default. It performs read operations plus server-side dry-run admission requests; it does not run the destructive game day.

## Still AWS-specific

The local runtime does **not** prove:

- GitHub OIDC assuming an AWS IAM role;
- S3/KMS Terraform remote state;
- an EKS control plane or managed node group;
- AWS load balancer/NAT/network behavior;
- AWS-specific OpenCost pricing;
- multi-region failover.

Those remain explicitly separated in the [Live Activation Runbook](LIVE_ACTIVATION.md).
