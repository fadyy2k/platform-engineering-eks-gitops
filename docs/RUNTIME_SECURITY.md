# Runtime Security and Admission Controls

Phase 3 adds controls at three different points so a single failed layer does not become the entire security model.

## 1. Kubernetes Pod Security Admission

The `platform-demo` namespace is labeled with the Kubernetes **restricted** Pod Security Standard in enforce, audit, and warn modes. The workload already satisfies the required posture: non-root execution, RuntimeDefault seccomp, no privilege escalation, read-only root filesystem, and all Linux capabilities dropped.

## 2. Network segmentation

The namespace starts with a default-deny ingress/egress `NetworkPolicy`.

The demo workload then receives only:

- TCP/8080 ingress from other pods in the same namespace
- TCP/UDP 53 egress to CoreDNS in `kube-system`

The demo service has no business requirement for arbitrary Internet egress, so none is granted. An ingress controller or service mesh would need an explicit additional allow rule before exposing the service outside the namespace.

## 3. Kyverno admission control

Kyverno chart `3.9.1` (app `v1.19.1`) is managed through Argo CD.

Two enforcing policies protect the demo namespace:

### Immutable digests

All normal, init, and ephemeral container images must use a SHA-256 digest. Mutable image tags are rejected.

### Keyless signature verification

Normal, init, and ephemeral images matching `ghcr.io/fadyy2k/platform-demo*` must have a valid Cosign keyless signature issued to the repository's `image.yml` GitHub Actions workflow by `https://token.actions.githubusercontent.com`. Rekor transparency-log verification is enabled.

The CI policy test contains both an accepted digest-pinned pod and a rejected mutable-tag pod. The signed production digest is also verified independently by Cosign in the image supply-chain workflow.

## 4. Continuous workload scanning

Trivy Operator chart `0.36.0` (app `v0.34.0`) is configured to maintain:

- vulnerability reports
- SBOMs
- configuration-audit reports
- RBAC assessments
- infrastructure assessments
- cluster compliance reports
- exposed-secret reports

Reports expire after 24 hours so the operator continually refreshes the security view instead of leaving a stale one-time scan. Global Secret/ServiceAccount access for scan jobs is explicitly disabled because this lab consumes a public GHCR image.

## 5. Falco runtime detections

Falco chart `9.1.0` (app `0.44.1`) is configured with the modern eBPF driver and the chart's least-privileged mode. Alerts at `notice` severity and above are emitted as JSON, and runtime metrics are enabled.

Falcosidekick is intentionally disabled in this baseline because no external alert destination has been selected. The next observability step can route Falco alerts to an approved SIEM/webhook without hard-coding a private endpoint into this public repository.

## GitOps order

```text
Argo CD
  ├─ Kyverno chart
  ├─ Trivy Operator chart
  ├─ Falco chart
  └─ Kyverno policy application
       └─ platform-demo
            ├─ Pod Security Admission
            ├─ image digest enforcement
            ├─ Cosign signature verification
            └─ default-deny network policy
```

The security controller applications use sync wave `0`; the policy application uses sync wave `1` so Kyverno is installed before its policies when these Applications are managed as a group.

## Activation

These manifests are **not deployed automatically from this repository** because an EKS cluster is not currently provisioned by the project. After the cluster and Argo CD exist, apply the controller Applications first, then the policy and workload Applications:

```bash
kubectl apply -f platform/argocd/kyverno-application.yaml
kubectl apply -f platform/argocd/trivy-operator-application.yaml
kubectl apply -f platform/argocd/falco-application.yaml
kubectl apply -f platform/argocd/security-policies-application.yaml
kubectl apply -f platform/argocd/platform-demo-application.yaml
```

Before production use, validate Falco modern-eBPF support on the selected EKS node AMI/kernel and add explicit network-policy rules for any ingress controller, telemetry collector, or service dependency introduced later.
