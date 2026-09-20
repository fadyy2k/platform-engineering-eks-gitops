# ADR-002: Optional Multi-Region Disaster-Recovery Pattern

**Status:** Architecture accepted; deployment deferred until a stateful production workload exists.

## Context

The platform currently models each environment as an independent Terraform state key. A second region should not be introduced until recovery objectives and state replication requirements are explicit.

## Decision

Use an **active/passive regional pattern** rather than active/active for the reference architecture.

```text
Primary region                         Recovery region
-------------                          ---------------
VPC + EKS                              VPC + EKS (warm/minimal)
GitOps desired state  ───────────────► same Git revision
Container digests     ───────────────► same signed GHCR digest
Backups               ── replicated ─► independent recovery storage
DNS / traffic control ── failover ───► recovery ingress
```

Each region receives a separate backend state key and separate network CIDR. Git remains the desired-state source; container promotion remains digest-based.

## Why not active/active now

Active/active would require validated cross-region data consistency, conflict behavior, traffic steering, observability correlation, and significantly more failure modes. The current demo service has no stateful business requirement that justifies that complexity.

## Activation requirements

Before deploying a recovery region:

1. define RTO and RPO per workload
2. choose the authoritative data replication mechanism
3. use a separate recovery-state key and non-overlapping CIDR
4. replicate backup objects to an independently controlled destination
5. test DNS/traffic failover and rollback
6. run the backup/restore smoke test in the recovery region
7. exercise a game day where the primary region is considered unavailable
8. measure actual recovery time and record gaps

The pattern is intentionally optional. A second region should not be provisioned solely to make the architecture diagram look more advanced.
