#!/usr/bin/env bash
set -euo pipefail

namespace="${NAMESPACE:-platform-demo}"
backup_name="${BACKUP_NAME:-platform-demo-smoke-$(date +%Y%m%d%H%M%S)}"
execute="${EXECUTE:-0}"

if [[ "$execute" != "1" ]]; then
  cat <<EOF2
[dry-run] would:
  1. create ConfigMap reliability-backup-marker in $namespace
  2. create Velero backup $backup_name for $namespace
  3. wait for Completed
  4. delete the marker
  5. restore from $backup_name
  6. assert marker data was recovered

Set EXECUTE=1 only against an approved non-production cluster with a working Velero backup location.
EOF2
  exit 0
fi

for cmd in kubectl velero python3; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "$cmd is required" >&2; exit 1; }
done

marker="recovery-$(date +%s)"
kubectl -n "$namespace" create configmap reliability-backup-marker \
  --from-literal=marker="$marker" \
  --dry-run=client -o yaml | kubectl apply -f -

velero backup create "$backup_name" \
  --include-namespaces "$namespace" \
  --wait

phase="$(velero backup get "$backup_name" -o json | python3 -c 'import json,sys; print(json.load(sys.stdin)["status"]["phase"])')"
[[ "$phase" == "Completed" ]] || { echo "backup phase is $phase" >&2; exit 1; }

kubectl -n "$namespace" delete configmap reliability-backup-marker
velero restore create --from-backup "$backup_name" --wait

restored="$(kubectl -n "$namespace" get configmap reliability-backup-marker -o jsonpath='{.data.marker}')"
[[ "$restored" == "$marker" ]] || { echo "restore mismatch: expected $marker got $restored" >&2; exit 1; }

echo "backup/restore smoke test passed: $backup_name"
