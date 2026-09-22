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

- [x] OpenCost visibility + tested monthly run-rate budget alert
- [x] VPA recommender-only right-sizing recommendations
- [x] Reusable Terraform platform module with environment-specific roots/state
- [x] Optional active/passive multi-region disaster-recovery pattern documented with activation criteria


## Phase 6 — Live-readiness Hardening

- [x] Move the EKS baseline to Kubernetes 1.36 with `STANDARD` support policy
- [x] Split monitoring-namespace and workload-namespace Argo applications
- [x] Add read-only activation preflight and dry-run Argo bootstrap helper
- [x] Add live activation/evidence runbooks, contribution guidance and issue templates
- [x] Capture public CI evidence without claiming a live cluster
- [ ] Provision an approved non-production AWS dev environment
- [ ] Prove GitHub OIDC + remote-state plan/apply against AWS
- [ ] Reconcile the platform with Argo CD and capture in-cluster security evidence
- [ ] Execute the controlled SLO game day and Velero restore drill
- [ ] Capture real OpenCost/VPA data and evaluate autoscaling from measured load


## Phase 7 — Local runtime evidence

- [x] Run Kubernetes 1.36 locally with Argo CD, Kyverno, Prometheus, Trivy and Falco
- [x] Prove signed-image admission and untrusted-image denial server-side
- [x] Capture Prometheus SLO scrape/rule evidence
- [x] Execute a controlled pod-failure recovery game day
- [x] Capture Trivy Operator and Falco runtime-security evidence
- [x] Capture VPA recommendation-only output
- [x] Capture OpenCost allocation data against in-cluster Prometheus
- [x] Add a reproducible kind/Kyverno admission workflow to GitHub Actions
- [ ] Keep AWS-specific OIDC/state/EKS evidence separate until an approved account is available


### Phase 7 runtime proof extensions

- [x] Prove mutable-tag denial and unknown-digest signature denial in local admission
- [x] Execute pod-failure and HTTP error-burn game days locally
- [x] Capture all-up Prometheus target state and SLO alert behavior
- [x] Capture OpenCost allocation and VPA recommendation output
- [x] Capture Falco Kubernetes-attributed runtime event
- [x] Capture Trivy Operator report inventory and findings
- [x] Complete namespace-mapped Velero backup/restore against local MinIO
- [ ] Repeat these runtime proofs in an approved AWS/EKS dev environment when access exists
