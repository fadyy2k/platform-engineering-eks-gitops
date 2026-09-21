# Engineering Evidence

This page separates **what the repository and CI prove today** from **what still requires a live AWS/EKS environment**.

## Current reproducible evidence

| Control | Evidence | Scope |
| --- | --- | --- |
| Terraform validation | [Terraform CI run 35513734871](https://github.com/fadyy2k/platform-engineering-eks-gitops/actions/runs/35513734871) | formatting/init/validate; no AWS resources created |
| Kubernetes validation | [Kubernetes CI run 35513734824](https://github.com/fadyy2k/platform-engineering-eks-gitops/actions/runs/35513734824) | schema/policy checks against desired state |
| Policy/runtime configuration | [Policy CI run 35513734787](https://github.com/fadyy2k/platform-engineering-eks-gitops/actions/runs/35513734787) | Kyverno tests + security chart rendering |
| Reliability rules | [Reliability CI run 35513734956](https://github.com/fadyy2k/platform-engineering-eks-gitops/actions/runs/35513734956) | app metrics tests, `promtool`, manifests, shellcheck |
| Cost/operations | [Cost & Operations run 35513734879](https://github.com/fadyy2k/platform-engineering-eks-gitops/actions/runs/35513734879) | OpenCost/VPA rendering + cost-rule tests |
| Signed demo image | [Supply-chain run 35513183442](https://github.com/fadyy2k/platform-engineering-eks-gitops/actions/runs/35513183442) | build, provenance/SBOM, Trivy, keyless Cosign sign/verify |

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

## Not yet claimed

The repository does **not** currently claim:

- a provisioned AWS EKS cluster;
- successful live GitHub OIDC role assumption;
- live Argo CD reconciliation;
- external Alertmanager delivery;
- a completed Velero restore drill;
- real OpenCost dollar/allocation data;
- live VPA recommendations;
- a multi-region failover test.

Those items move to the proven column only after the [Live Activation Runbook](LIVE_ACTIVATION.md) is executed in an approved non-production account and evidence is captured.
