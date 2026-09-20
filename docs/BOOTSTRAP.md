# AWS Bootstrap: Remote State and GitHub OIDC

The main EKS stack does not require long-lived AWS keys in GitHub. A small, separate Terraform root under `bootstrap/` creates the trust and state primitives first.

## What the bootstrap stack creates

- S3 bucket with public access blocked, versioning enabled, TLS-only access, and `force_destroy = false`
- customer-managed KMS key with key rotation for Terraform state encryption
- GitHub Actions OIDC provider for `https://token.actions.githubusercontent.com`
- `platform-lab-github-plan` role for state access and read-only AWS discovery
- `platform-lab-github-apply` role for the VPC/EKS mutations used by this repository

The apply trust policy accepts only GitHub OIDC subjects for the `dev`, `staging`, and `prod` GitHub Environments. The plan role accepts only this repository's pull-request subject and protected `main` branch subject.

## Prerequisites

Use a short-lived administrator/bootstrap session from an approved workstation. Examples include AWS IAM Identity Center / SSO or another temporary privileged role.

Do **not** create an IAM user access key just for CI.

## 1. Review and apply the bootstrap stack

```bash
cp bootstrap/terraform.tfvars.example bootstrap/terraform.tfvars
terraform -chdir=bootstrap init
terraform -chdir=bootstrap fmt -check -recursive
terraform -chdir=bootstrap validate
terraform -chdir=bootstrap plan
terraform -chdir=bootstrap apply
```

The bootstrap apply creates persistent account-level security resources. Review the plan before applying it.

## 2. Render local backend files

Backend files contain account-specific bucket and KMS identifiers, so generated copies are ignored by Git.

```bash
./scripts/render-backend-config.sh dev
./scripts/render-backend-config.sh staging
./scripts/render-backend-config.sh prod
```

Each generated file uses a separate state key:

```text
platform/dev/terraform.tfstate
platform/staging/terraform.tfstate
platform/prod/terraform.tfstate
```

Terraform 1.16 uses S3 native state locking through `use_lockfile = true`, so a separate DynamoDB lock table is not required for this project.

## 3. Initialize the main stack

Example for development:

```bash
terraform -chdir=infra init -reconfigure \
  -backend-config=environments/dev.backend.hcl

terraform -chdir=infra plan \
  -var-file=environments/dev.tfvars.example
```

Repeat with the matching backend and variable files for staging or production.

## 4. Configure GitHub repository variables and environments

After bootstrap outputs exist:

```bash
./scripts/configure-github-repo.sh
```

The script configures these GitHub repository variables:

- `AWS_REGION`
- `TF_STATE_BUCKET`
- `TF_STATE_KMS_KEY_ARN`
- `AWS_TERRAFORM_PLAN_ROLE_ARN`
- `AWS_TERRAFORM_APPLY_ROLE_ARN`

It also creates `dev`, `staging`, and `prod` GitHub Environments restricted to protected branches.

## 5. CI behavior after activation

- ordinary PRs always get local Terraform format/validate checks with **no AWS credentials**
- cloud-backed Terraform plans run only when the OIDC/backend variables are configured
- cloud-backed plans are skipped for fork PRs, preventing untrusted fork code from receiving the plan role
- applies are `workflow_dispatch` only, require the literal confirmation `APPLY`, run from protected `main`, and use a GitHub Environment-scoped OIDC subject

## Bootstrap state handling

The first bootstrap apply starts with local state because the remote backend does not exist yet. Treat `bootstrap/terraform.tfstate` as sensitive and do not commit it. After the state bucket exists, one option is to migrate the bootstrap state into a separately named key in the same secured bucket after an explicit review.

The repository does not automate that migration because changing the trust/state foundation should be an intentional operator action.
