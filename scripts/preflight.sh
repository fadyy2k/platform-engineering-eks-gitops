#!/usr/bin/env bash
set -euo pipefail

MODE="full"
if [[ "${1:-}" == "--local" ]]; then MODE="local"; fi

ok()   { printf 'OK    %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*" >&2; failures=$((failures + 1)); }

failures=0
printf 'Platform live-activation preflight (%s mode)\n' "$MODE"
printf '%s\n' '------------------------------------------------------------'

for tool in git docker jq; do
  if command -v "$tool" >/dev/null 2>&1; then ok "$tool available"; else fail "$tool is required"; fi
done

for tool in terraform kubectl helm aws gh; do
  if command -v "$tool" >/dev/null 2>&1; then ok "$tool available"; else warn "$tool not installed in this shell"; fi
done

expected_version=$(awk -F'"' '/kubernetes_version/ {print $2; exit}' infra/environments/dev.tfvars.example)
printf 'INFO  dev Kubernetes baseline: %s\n' "$expected_version"
printf 'INFO  EKS API public access: disabled by default (private-first)\n'
printf 'INFO  cost-sensitive resources: EKS control plane, NAT gateway, EC2 nodes, EBS, public IPv4/data transfer\n'

if [[ "$MODE" == "full" ]]; then
  if ! command -v aws >/dev/null 2>&1; then
    fail "AWS CLI is required for cloud activation"
  else
    identity=$(aws sts get-caller-identity --output json 2>/dev/null || true)
    if [[ -z "$identity" ]]; then
      fail "no usable AWS session; authenticate with a short-lived approved identity"
    else
      account=$(jq -r '.Account' <<<"$identity")
      arn=$(jq -r '.Arn' <<<"$identity")
      region=$(aws configure get region 2>/dev/null || true)
      region=${AWS_REGION:-${AWS_DEFAULT_REGION:-$region}}
      [[ -n "$region" ]] || region="<unset>"
      ok "AWS identity resolved: account ${account}, principal ${arn}"
      printf 'INFO  AWS region: %s\n' "$region"
      warn "review the Terraform plan and current AWS pricing before every apply"
    fi
  fi
fi

if (( failures > 0 )); then
  printf '\nPreflight failed with %d blocking issue(s).\n' "$failures" >&2
  exit 1
fi
printf '\nPreflight passed. No cloud resources were changed.\n'
