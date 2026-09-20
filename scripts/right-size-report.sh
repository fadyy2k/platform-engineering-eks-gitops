#!/usr/bin/env bash
set -euo pipefail

namespace="${NAMESPACE:-platform-demo}"
vpa_name="${VPA_NAME:-platform-demo}"

for cmd in kubectl python3; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "$cmd is required" >&2; exit 1; }
done

kubectl -n "$namespace" get vpa "$vpa_name" -o json | python3 -c '
import json,sys
obj=json.load(sys.stdin)
recs=obj.get("status",{}).get("recommendation",{}).get("containerRecommendations",[])
if not recs:
    raise SystemExit("no VPA recommendation available yet")
print("container\ttarget_cpu\ttarget_memory\tlower_cpu\tlower_memory\tupper_cpu\tupper_memory")
for r in recs:
    target=r.get("target",{})
    lower=r.get("lowerBound",{})
    upper=r.get("upperBound",{})
    print("\t".join([
        r.get("containerName","?"),
        target.get("cpu","-"), target.get("memory","-"),
        lower.get("cpu","-"), lower.get("memory","-"),
        upper.get("cpu","-"), upper.get("memory","-")
    ]))
'
