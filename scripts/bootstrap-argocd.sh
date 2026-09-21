#!/usr/bin/env bash
set -euo pipefail

ARGO_CHART_VERSION="${ARGO_CHART_VERSION:-10.9.2}"
ARGO_NAMESPACE="${ARGO_NAMESPACE:-argocd}"
EXECUTE="${EXECUTE:-0}"

for tool in kubectl helm; do
  command -v "$tool" >/dev/null 2>&1 || { echo "missing required tool: $tool" >&2; exit 1; }
done

context=$(kubectl config current-context 2>/dev/null || true)
[[ -n "$context" ]] || { echo "no kubectl context selected" >&2; exit 1; }
echo "kubectl context: $context"
echo "Argo CD chart: argo-cd ${ARGO_CHART_VERSION}"
echo "Argo CD server remains ClusterIP; this script does not expose an administrative UI publicly."

if [[ "$EXECUTE" != "1" ]]; then
  cat <<'EOF'
DRY RUN: no cluster changes made.
To execute against an approved non-production cluster:
  EXECUTE=1 ./scripts/bootstrap-argocd.sh
EOF
  exit 0
fi

kubectl auth can-i create deployments -n "$ARGO_NAMESPACE" >/dev/null 2>&1 || true
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo update argo >/dev/null
helm upgrade --install argocd argo/argo-cd \
  --version "$ARGO_CHART_VERSION" \
  --namespace "$ARGO_NAMESPACE" \
  --create-namespace \
  --set server.service.type=ClusterIP \
  --wait --timeout 10m

kubectl apply -f platform/argocd/monitoring-application.yaml
kubectl apply -f platform/argocd/metrics-server-application.yaml
kubectl apply -f platform/argocd/kyverno-application.yaml
kubectl apply -f platform/argocd/trivy-operator-application.yaml
kubectl apply -f platform/argocd/falco-application.yaml
kubectl apply -f platform/argocd/security-policies-application.yaml
kubectl apply -f platform/argocd/platform-demo-application.yaml
kubectl apply -f platform/argocd/reliability-application.yaml
kubectl apply -f platform/argocd/reliability-monitoring-application.yaml
kubectl apply -f platform/argocd/vpa-application.yaml
kubectl apply -f platform/argocd/opencost-application.yaml
kubectl apply -f platform/argocd/cost-controls-application.yaml
kubectl apply -f platform/argocd/cost-monitoring-application.yaml

echo "Argo CD bootstrap submitted. Verify reconciliation before calling the environment healthy."
