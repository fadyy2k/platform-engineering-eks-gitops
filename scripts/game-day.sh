#!/usr/bin/env bash
set -euo pipefail

namespace="${NAMESPACE:-platform-demo}"
deployment="${DEPLOYMENT:-platform-demo}"
scenario="${1:-}"
execute="${EXECUTE:-0}"
allow_prod="${ALLOW_PROD:-0}"
environment="${ENVIRONMENT:-dev}"

usage() {
  cat <<USAGE
Usage: $0 <pod-failure|error-burn>

Defaults to dry-run. Set EXECUTE=1 to make changes.
ENVIRONMENT defaults to dev. Production requires ALLOW_PROD=1 explicitly.
USAGE
}

case "$scenario" in
  pod-failure|error-burn) ;;
  *) usage >&2; exit 2 ;;
esac

if [[ "$environment" == "prod" && "$allow_prod" != "1" ]]; then
  echo "refusing production game day without ALLOW_PROD=1" >&2
  exit 3
fi

if [[ "$execute" != "1" ]]; then
  case "$scenario" in
    pod-failure)
      echo "[dry-run] would delete one $deployment pod in namespace $namespace and wait for Deployment recovery"
      ;;
    error-burn)
      echo "[dry-run] would set FAIL_MODE=true, wait for rollout, generate 200 HTTP requests, then restore the Deployment"
      ;;
  esac
  exit 0
fi

command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required" >&2; exit 1; }
if [[ "$scenario" == "error-burn" ]]; then
  command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
fi

case "$scenario" in
  pod-failure)
    pod="$(kubectl -n "$namespace" get pods -l app.kubernetes.io/name="$deployment" -o jsonpath='{.items[0].metadata.name}')"
    [[ -n "$pod" ]] || { echo "no matching pod found" >&2; exit 1; }
    echo "scenario: delete one pod and verify the deployment returns to ready state"
    kubectl -n "$namespace" delete pod "$pod" --wait=false
    kubectl -n "$namespace" rollout status deployment/"$deployment" --timeout=180s
    kubectl -n "$namespace" get pods -l app.kubernetes.io/name="$deployment" -o wide
    ;;

  error-burn)
    echo "scenario: inject HTTP 503 responses, generate traffic, then restore normal behavior"
    kubectl -n "$namespace" set env deployment/"$deployment" FAIL_MODE=true

    restore() {
      kubectl -n "$namespace" set env deployment/"$deployment" FAIL_MODE- >/dev/null 2>&1 || true
      kubectl -n "$namespace" rollout status deployment/"$deployment" --timeout=180s >/dev/null 2>&1 || true
      [[ -n "${pf_pid:-}" ]] && kill "$pf_pid" >/dev/null 2>&1 || true
    }
    trap restore EXIT

    kubectl -n "$namespace" rollout status deployment/"$deployment" --timeout=180s
    kubectl -n "$namespace" port-forward service/"$deployment" 18080:80 >/tmp/platform-demo-port-forward.log 2>&1 &
    pf_pid=$!
    sleep 3

    for _ in $(seq 1 200); do
      curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:18080/ || true
    done

    echo "traffic injected; restoring deployment"
    restore
    trap - EXIT
    ;;
esac
