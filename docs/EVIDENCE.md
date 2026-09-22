# Engineering Evidence

This page separates **what the repository and CI prove today** from **what still requires a live AWS/EKS environment**.

## Current reproducible evidence

| Control | Evidence | Scope |
| --- | --- | --- |
| Terraform validation | [Terraform CI run 35611244984](https://github.com/fadyy2k/platform-engineering-eks-gitops/actions/runs/35611244984) | formatting/init/validate; no AWS resources created |
| Kubernetes validation | [Kubernetes CI run 35611244558](https://github.com/fadyy2k/platform-engineering-eks-gitops/actions/runs/35611244558) | schema/policy checks against desired state |
| Policy/runtime configuration | [Policy CI run 35611244115](https://github.com/fadyy2k/platform-engineering-eks-gitops/actions/runs/35611244115) | Kyverno tests + security chart rendering |
| Reliability rules | [Reliability CI run 35611244574](https://github.com/fadyy2k/platform-engineering-eks-gitops/actions/runs/35611244574) | app metrics tests, `promtool`, manifests, shellcheck |
| Cost/operations | [Cost & Operations run 35611245003](https://github.com/fadyy2k/platform-engineering-eks-gitops/actions/runs/35611245003) | OpenCost/VPA rendering + cost-rule tests |
| Signed demo image | [Supply-chain run 35513183442](https://github.com/fadyy2k/platform-engineering-eks-gitops/actions/runs/35513183442) | build, provenance/SBOM, Trivy, keyless Cosign sign/verify |
| Live-readiness boundaries | [Live Readiness CI run 35611244945](https://github.com/fadyy2k/platform-engineering-eks-gitops/actions/runs/35611244945) | EKS baseline, namespace boundaries, activation helper checks |

Verified Phase-4 image digest:

```text
sha256:5fc1d1e30a9a7ec08830000b794dd5fefdec2026782224f9bb6bf87de89889db
```

## Evidence gallery

The screenshots below are captures of **public GitHub Actions pages**, not mocked dashboards.

- [Supply-chain run](assets/evidence/supply-chain-run.png)
- [Policy/runtime CI](assets/evidence/policy-runtime-ci.png)
- [Reliability CI](assets/evidence/reliability-ci.png)
- [Cost & operations CI](assets/evidence/cost-operations-ci.png)
- [Live Readiness CI](assets/evidence/live-readiness-ci.png)


## Local runtime evidence

Static CI is complemented by a real disposable `kind` runtime on Kubernetes 1.36.4. The local environment has demonstrated:

- Argo CD Healthy/Synced reconciliation for the demo, policy and cost-control applications;
- successful admission of the signed immutable demo image and denial of an untrusted image;
- Prometheus discovery of both demo replicas and loaded SLO rule groups;
- an in-cluster Trivy Operator report with zero critical/high/medium/low findings for the pinned demo digest at capture time;
- a benign Falco syscall detection tied to a temporary Kubernetes pod;
- recovery after a controlled pod-deletion game day;
- VPA recommendation-only output;
- OpenCost namespace allocation data against the in-cluster Prometheus service.
- namespace-mapped Velero backup/restore completed locally with the restored Deployment reaching 2/2;
- controlled error-burn generated 200 HTTP 503 responses and recovered to 2/2;

See [Local Runtime Evidence](LOCAL_RUNTIME.md) for the transcript, screenshots, scope and limitations.

## Not yet claimed

The repository does **not** currently claim:

- a provisioned AWS EKS cluster;
- successful live GitHub OIDC role assumption;
- live Argo CD reconciliation **in EKS**;
- external Alertmanager delivery;
- a Velero restore drill backed by AWS/EKS infrastructure;
- AWS-priced OpenCost allocation data;
- VPA recommendations from an EKS workload profile;
- a multi-region failover test.

Those items move to the proven column only after the [Live Activation Runbook](LIVE_ACTIVATION.md) is executed in an approved non-production account and evidence is captured.
