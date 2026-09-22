#!/usr/bin/env bash
set -euo pipefail

context="${KUBE_CONTEXT:-$(kubectl config current-context 2>/dev/null || true)}"
allow_non_kind="${ALLOW_NON_KIND:-0}"
prom_port="${PROM_PORT:-29090}"
opencost_port="${OPENCOST_PORT:-29003}"

for tool in kubectl curl jq; do
  command -v "$tool" >/dev/null 2>&1 || { echo "missing required tool: $tool" >&2; exit 1; }
done

[[ -n "$context" ]] || { echo "no kubectl context selected" >&2; exit 1; }
if [[ "$context" != kind-* && "$allow_non_kind" != "1" ]]; then
  echo "refusing to run against non-kind context '$context' without ALLOW_NON_KIND=1" >&2
  exit 2
fi

k() { kubectl --context "$context" "$@"; }
cleanup() {
  [[ -n "${prom_pid:-}" ]] && kill "$prom_pid" >/dev/null 2>&1 || true
  [[ -n "${opencost_pid:-}" ]] && kill "$opencost_pid" >/dev/null 2>&1 || true
  rm -f /tmp/platform-runtime-good.yaml /tmp/platform-runtime-bad.yaml
}
trap cleanup EXIT

printf 'Local runtime verification\n'
printf 'context=%s\n' "$context"
k get nodes -o custom-columns='NAME:.metadata.name,STATUS:.status.conditions[-1].type,VERSION:.status.nodeInfo.kubeletVersion'

echo
echo 'Argo CD applications:'
apps=(platform-demo platform-security-policies vertical-pod-autoscaler opencost cost-controls cost-monitoring-resources)
for app in "${apps[@]}"; do
  health=$(k -n argocd get application "$app" -o jsonpath='{.status.health.status}' 2>/dev/null || true)
  sync=$(k -n argocd get application "$app" -o jsonpath='{.status.sync.status}' 2>/dev/null || true)
  printf '  %-30s health=%-8s sync=%s\n' "$app" "${health:-missing}" "${sync:-missing}"
  [[ "$health" == "Healthy" && "$sync" == "Synced" ]] || { echo "application $app is not Healthy/Synced" >&2; exit 1; }
done

image=$(k -n platform-demo get deployment platform-demo -o jsonpath='{.spec.template.spec.containers[0].image}')
cat >/tmp/platform-runtime-good.yaml <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: signed-image-admission-probe
  namespace: platform-demo
spec:
  automountServiceAccountToken: false
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: ${image}
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
      resources:
        requests: {cpu: 10m, memory: 16Mi}
        limits: {cpu: 100m, memory: 64Mi}
YAML
cat >/tmp/platform-runtime-bad.yaml <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: rejected-image-admission-probe
  namespace: platform-demo
spec:
  automountServiceAccountToken: false
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: nginx:1.27
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
      resources:
        requests: {cpu: 10m, memory: 16Mi}
        limits: {cpu: 100m, memory: 64Mi}
YAML

echo
echo 'Admission controls:'
k apply --dry-run=server -f /tmp/platform-runtime-good.yaml -o name >/dev/null
echo '  signed project image: admitted'
set +e
bad_output=$(k apply --dry-run=server -f /tmp/platform-runtime-bad.yaml 2>&1)
bad_rc=$?
set -e
[[ $bad_rc -ne 0 ]] || { echo 'unsigned/non-project image unexpectedly admitted' >&2; exit 1; }
grep -q 'validate-platform-demo-images' <<<"$bad_output" || { echo "$bad_output" >&2; exit 1; }
echo '  nginx:1.27: denied by image policy'

echo
echo 'Trivy Operator:'
report=$(k -n platform-demo get vulnerabilityreports.aquasecurity.github.io -o jsonpath='{.items[0].metadata.name}')
k -n platform-demo get vulnerabilityreport "$report" -o json | jq -r '"  digest=" + .report.artifact.digest + " critical=" + (.report.summary.criticalCount|tostring) + " high=" + (.report.summary.highCount|tostring) + " medium=" + (.report.summary.mediumCount|tostring) + " low=" + (.report.summary.lowCount|tostring)'

k -n monitoring port-forward svc/prometheus-operated "${prom_port}:9090" >/tmp/platform-prometheus-pf.log 2>&1 &
prom_pid=$!
for _ in $(seq 1 30); do curl -fsS "http://127.0.0.1:${prom_port}/-/ready" >/dev/null 2>&1 && break; sleep 1; done
curl -fsS "http://127.0.0.1:${prom_port}/-/ready" >/dev/null

echo
echo 'Prometheus:'
up=$(curl -fsSG --data-urlencode 'query=up{namespace="platform-demo"}' "http://127.0.0.1:${prom_port}/api/v1/query" | jq '[.data.result[].value[1] | tonumber] | add')
total=$(curl -fsSG --data-urlencode 'query=up{namespace="platform-demo"}' "http://127.0.0.1:${prom_port}/api/v1/query" | jq '.data.result|length')
printf '  platform-demo scrape targets up=%s/%s\n' "$up" "$total"
[[ "$up" == "$total" && "$total" -gt 0 ]] || { echo 'platform-demo scrape target is not fully healthy' >&2; exit 1; }
curl -fsS "http://127.0.0.1:${prom_port}/api/v1/rules" | jq -r '.data.groups[] | select(.name|contains("platform-demo")) | "  rule-group=" + .name + " rules=" + (.rules|length|tostring)'

echo
echo 'VPA (recommendation only):'
k -n platform-demo get vpa platform-demo -o json | jq -r '"  updateMode=" + .spec.updatePolicy.updateMode + " targetCPU=" + .status.recommendation.containerRecommendations[0].target.cpu + " targetMemory=" + .status.recommendation.containerRecommendations[0].target.memory'

k -n opencost port-forward svc/opencost "${opencost_port}:9003" >/tmp/platform-opencost-pf.log 2>&1 &
opencost_pid=$!
for _ in $(seq 1 30); do curl -fsS "http://127.0.0.1:${opencost_port}/healthz" >/dev/null 2>&1 && break; sleep 1; done

echo
echo 'OpenCost local allocation:'
curl -fsS "http://127.0.0.1:${opencost_port}/allocation/compute?window=1h&aggregate=namespace" | jq -r '.data[0]["platform-demo"] | "  cpuUsageAverage=" + (.cpuCoreUsageAverage|tostring) + " cpuRequestAverage=" + (.cpuCoreRequestAverage|tostring) + " totalCost=" + (.totalCost|tostring) + " efficiency=" + (.totalEfficiency|tostring)'
echo '  pricing scope: local kind/default provider; not an AWS bill'

echo
echo 'PASS: local runtime controls are observable and admission is enforced.'
