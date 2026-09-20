#!/usr/bin/env bash
set -euo pipefail

env_name="${1:-}"
case "$env_name" in
  dev|staging|prod) ;;
  *) echo "usage: $0 <dev|staging|prod>" >&2; exit 2 ;;
esac

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bootstrap_dir="$repo_root/bootstrap"
out="$repo_root/infra/environments/${env_name}.backend.hcl"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required" >&2
  exit 1
fi

bucket="$(terraform -chdir="$bootstrap_dir" output -raw state_bucket_name)"
kms_arn="$(terraform -chdir="$bootstrap_dir" output -raw state_kms_key_arn)"
region="$(terraform -chdir="$bootstrap_dir" output -raw aws_region)"

cat > "$out" <<HCL
bucket       = "$bucket"
key          = "platform/${env_name}/terraform.tfstate"
region       = "$region"
encrypt      = true
kms_key_id   = "$kms_arn"
use_lockfile = true
HCL

chmod 600 "$out"
echo "wrote $out"
