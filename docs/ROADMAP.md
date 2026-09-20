# Roadmap

The repository starts as a safe, reproducible platform baseline and grows by adding controls only when they are testable.

## Phase 1 — Baseline

- [x] Terraform-managed VPC and EKS
- [x] Managed EKS node group
- [x] Private-first EKS API setting
- [x] EBS CSI add-on
- [x] Argo CD Application for a demo workload
- [x] Prometheus/Grafana values
- [x] Terraform, Kubernetes and security CI
- [x] Dependabot and secret scanning

## Phase 2 — Identity and Delivery

- [x] GitHub Actions → AWS OIDC federation (bootstrap code; AWS activation is explicit)
- [x] Dedicated scoped plan/apply roles
- [x] Remote Terraform state with KMS encryption, S3 native locking, versioning and recovery documentation
- [x] Environment promotion model: dev → staging → prod
- [x] Signed container supply chain with Cosign keyless GitHub OIDC

## Phase 3 — Policy and Runtime Security

- [x] Kyverno policy-as-code with modern ValidatingPolicy/ImageValidatingPolicy APIs
- [x] Default-deny NetworkPolicy baseline with explicit DNS and same-namespace app traffic
- [x] Trivy Operator continuous vulnerability/config/RBAC/compliance scanning
- [x] Falco runtime detections using modern eBPF with least-privileged mode
- [x] Pod Security Admission restricted namespace policy

## Phase 4 — Reliability

- [x] SLOs, recording rules and multi-window error-budget burn alerts
- [x] Severity-aware Alertmanager routing topology (external receiver intentionally environment-specific)
- [x] Workload HPA + documented Cluster Autoscaler/Karpenter evaluation
- [x] Executable backup/restore smoke-test harness (live execution requires an approved cluster + Velero)
- [x] Dry-run-by-default game-day failure scenarios and operator runbooks

## Phase 5 — Cost and Multi-environment Operations

- [ ] Cost visibility and budget alerts
- [ ] Right-sizing recommendations
- [ ] Reusable environment modules
- [ ] Optional multi-region disaster-recovery pattern
