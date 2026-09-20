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

- [ ] GitHub Actions → AWS OIDC federation
- [ ] Dedicated least-privilege plan/apply roles
- [ ] Remote Terraform state with encryption, locking and recovery documentation
- [ ] Environment promotion model: dev → staging → prod
- [ ] Signed container images with Cosign

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
