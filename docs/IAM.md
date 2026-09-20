# IAM and OIDC Model

## No long-lived CI credentials

GitHub Actions receives short-lived AWS credentials through OpenID Connect. The repository never requires an AWS access key or secret access key to be stored in GitHub.

## Trust boundaries

### Plan role

Accepted GitHub OIDC subjects:

```text
repo:fadyy2k/platform-engineering-eks-gitops:pull_request
repo:fadyy2k/platform-engineering-eks-gitops:ref:refs/heads/main
```

The cloud-backed plan job additionally refuses fork pull requests. Fork PRs still receive static Terraform validation without AWS access.

### Apply role

Accepted subjects:

```text
repo:fadyy2k/platform-engineering-eks-gitops:environment:dev
repo:fadyy2k/platform-engineering-eks-gitops:environment:staging
repo:fadyy2k/platform-engineering-eks-gitops:environment:prod
```

The apply workflow must be dispatched from `main` and enter the matching GitHub Environment.

## Permissions strategy

The plan role has:

- read/write access only to Terraform state objects and state lock files
- KMS access only to the state encryption key
- read-only discovery APIs needed by Terraform refresh/plan

The apply role has:

- the same tightly scoped state access
- enumerated VPC/EC2 networking actions used by the VPC module
- enumerated EKS cluster/node group/add-on actions
- IAM role/policy mutation restricted to names prefixed by the project (`platform-lab-*` by default)
- `iam:PassRole` restricted to project-prefixed roles and EKS/EC2 service principals
- service-linked-role creation restricted by `iam:AWSServiceName`

The policy intentionally avoids `AdministratorAccess`, `PowerUserAccess`, and wildcard service actions such as `ec2:*` or `iam:*`.

## Production tightening

A reusable lab still cannot predict every organization control, SCP, existing service-linked role, or future provider API call. Before production use:

1. apply in an isolated non-production AWS account
2. capture denied calls through CloudTrail
3. add only the exact missing action where justified
4. use IAM Access Analyzer policy generation after a representative deployment
5. introduce a permissions boundary for Terraform-created IAM roles if the organization uses one
6. separate bootstrap administration from routine platform applies

The target is evidence-driven least privilege rather than silently escalating the role to a broad AWS managed policy.
