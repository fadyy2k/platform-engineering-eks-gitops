# Reliability Runbooks

## PlatformDemoFastErrorBudgetBurn

**Signal:** 5-minute and 1-hour HTTP error ratios both exceed the 14.4x burn threshold for the 99.5% availability SLO.

1. confirm the alert is not caused by a planned game day or maintenance window
2. inspect current Deployment rollout and replica readiness
3. compare the current image digest with the last known-good Git revision
4. inspect pod restarts, readiness failures, and recent Argo CD syncs
5. check application logs for 5xx causes
6. if a recent release correlates with the burn, roll back through Git rather than patching desired state out-of-band
7. verify error rate returns below threshold and record the incident timeline

Escalate immediately if the burn is sustained, affects more than one environment, or rollback does not reduce errors.

## PlatformDemoSlowErrorBudgetBurn

**Signal:** 30-minute and 6-hour error ratios both exceed the 6x burn threshold.

1. inspect error distribution and request volume
2. check for intermittent dependency, capacity, or node pressure patterns
3. compare HPA behavior with request load and pod CPU
4. inspect recent configuration drift or repeated pod rescheduling
5. create a corrective issue even if customer impact is low; slow burn can exhaust the monthly budget without a dramatic outage

## PlatformDemoTargetDown

**Signal:** Prometheus cannot scrape the demo target for five minutes.

1. verify ServiceMonitor selector matches the Service labels
2. verify Service endpoints and ready pods exist
3. inspect NetworkPolicy changes
4. confirm Prometheus has namespace discovery permission and the target appears under Prometheus targets
5. distinguish application failure from monitoring-path failure before declaring service outage

## HPAAtMaximumCapacity

If the Deployment remains at `maxReplicas: 6` and latency/errors rise:

1. verify metrics-server and HPA conditions
2. check whether pods are Pending because nodes lack capacity
3. inspect CPU throttling and memory pressure
4. decide whether the problem is pod scaling, node scaling, or an upstream dependency
5. do not simply increase max replicas without validating node and downstream capacity

## BackupRestoreFailure

1. stop destructive maintenance on the affected namespace
2. preserve the failed backup/restore logs and Velero object status
3. verify backup storage availability and credentials
4. inspect volume snapshot and object-store errors separately
5. retry only after identifying whether the failure occurred during backup capture, object persistence, restore admission, or volume recreation
6. if recovery cannot be demonstrated within the target RTO, escalate the recovery incident
