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

- [ ] Kyverno or Gatekeeper policy-as-code
- [ ] NetworkPolicy baseline
- [ ] Trivy Operator or equivalent continuous workload scanning
- [ ] Falco runtime detections
- [ ] Pod Security Admission namespace policy

## Phase 4 — Reliability

- [ ] SLOs and recording rules
- [ ] Alert routing
- [ ] Cluster autoscaling / Karpenter evaluation
- [ ] Backup and restore tests
- [ ] Game-day failure scenarios and runbooks

## Phase 5 — Cost and Multi-environment Operations

- [ ] Cost visibility and budget alerts
- [ ] Right-sizing recommendations
- [ ] Reusable environment modules
- [ ] Optional multi-region disaster-recovery pattern
