#!/usr/bin/env bash
set -euo pipefail

repo="${GITHUB_REPOSITORY:-fadyy2k/platform-engineering-eks-gitops}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for cmd in gh terraform; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "$cmd is required" >&2; exit 1; }
done

gh auth status >/dev/null

bucket="$(terraform -chdir="$root/bootstrap" output -raw state_bucket_name)"
kms_arn="$(terraform -chdir="$root/bootstrap" output -raw state_kms_key_arn)"
plan_role="$(terraform -chdir="$root/bootstrap" output -raw github_plan_role_arn)"
apply_role="$(terraform -chdir="$root/bootstrap" output -raw github_apply_role_arn)"
region="$(terraform -chdir="$root/bootstrap" output -raw aws_region)"

gh variable set AWS_REGION --repo "$repo" --body "$region"
gh variable set TF_STATE_BUCKET --repo "$repo" --body "$bucket"
gh variable set TF_STATE_KMS_KEY_ARN --repo "$repo" --body "$kms_arn"
gh variable set AWS_TERRAFORM_PLAN_ROLE_ARN --repo "$repo" --body "$plan_role"
gh variable set AWS_TERRAFORM_APPLY_ROLE_ARN --repo "$repo" --body "$apply_role"

for env_name in dev staging prod; do
  printf '%s' '{"wait_timer":0,"deployment_branch_policy":{"protected_branches":true,"custom_branch_policies":false}}' | \
    gh api --method PUT "repos/$repo/environments/$env_name" --input - >/dev/null
  echo "configured GitHub Environment: $env_name"
done

echo "repository OIDC/backend variables configured for $repo"
