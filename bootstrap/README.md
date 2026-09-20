# Bootstrap Layer

This Terraform stack creates the account-level primitives that must exist **before** the main EKS configuration can use remote state and GitHub OIDC.

It creates:

- private, versioned S3 state bucket
- KMS key with rotation enabled
- S3 native state locking support (`use_lockfile = true` in the main backend)
- GitHub Actions OIDC provider
- read-only Terraform **plan** role
- environment-scoped Terraform **apply** role

The plan role can read AWS platform state and access the Terraform backend. The apply role can mutate the VPC/EKS resources used by this project and manage only IAM roles/policies prefixed with `platform-lab-` by default.

The bootstrap stack intentionally remains separate because Terraform cannot create the backend used by the same initialization step.

See [`docs/BOOTSTRAP.md`](../docs/BOOTSTRAP.md) for the complete sequence.
