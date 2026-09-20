# Environment Promotion Model

The same Terraform code is promoted through three independent state files and variable sets.

| Environment | VPC CIDR | Default nodes | Intended use |
| --- | --- | ---: | --- |
| `dev` | `10.20.0.0/16` | 2 × `t3.medium` | integration and platform development |
| `staging` | `10.30.0.0/16` | 2 × `t3.medium` | pre-production validation |
| `prod` | `10.40.0.0/16` | 3 × `t3.large` | production-like reference configuration |

These are example values, not a cost recommendation. Review capacity and pricing before creating resources.

## Promotion rule

```text
feature branch
    │
    ├─ static CI / security checks
    │
    ▼
pull request
    │
    ├─ OIDC Terraform plans (trusted same-repo PRs only)
    │      ├─ dev
    │      ├─ staging
    │      └─ prod
    ▼
protected main
    │
    ├─ manual apply → dev
    ├─ validation / soak
    ├─ manual apply → staging
    ├─ validation / soak
    └─ manual apply → prod
```

Each apply is a separate manual GitHub Actions dispatch and uses the matching GitHub Environment. A production organization can add required reviewers, wait timers, change-management IDs, or external deployment protection rules without modifying Terraform code.

## Why separate state instead of workspaces

Separate backend keys make the blast radius and operator intent explicit. A command targeting `prod` cannot silently switch workspaces inside the same initialized backend. It also makes backup/recovery and access-control decisions easier to reason about.

## Drift

The PR plan workflow compares desired configuration against the environment's remote state. For a production platform, add a scheduled drift-detection workflow that opens an issue or sends an alert rather than applying changes automatically.
