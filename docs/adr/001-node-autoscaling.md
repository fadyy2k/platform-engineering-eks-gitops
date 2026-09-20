# ADR-001: Node Autoscaling Strategy

**Status:** Accepted for the reference architecture; activation deferred until a live workload baseline exists.

## Context

The current EKS module uses a managed node group with explicit minimum, desired, and maximum sizes. Phase 4 adds workload HPA, which can create Pending pods when node capacity is exhausted. A node autoscaler is therefore required before calling the platform production-ready under variable load.

## Options considered

### Kubernetes Cluster Autoscaler

Advantages:

- mature behavior around managed node groups
- simple fit when instance families and node groups are already predetermined
- smaller operational change from the current Terraform model

Trade-offs:

- scales existing node groups rather than selecting from a broader capacity market
- node-group design becomes part of capacity planning
- less flexible consolidation than Karpenter

### Karpenter

Advantages:

- chooses instance capacity directly from scheduling requirements
- faster provisioning path for heterogeneous workloads
- consolidation and disruption controls can reduce idle capacity
- fewer static node-group shapes are needed

Trade-offs:

- additional controller/IAM/EventBridge/SQS integration
- NodePool/EC2NodeClass policy becomes a new production control plane
- disruption budgets and consolidation need workload-specific validation
- adopting it before real load data risks optimizing a hypothetical workload

## Decision

Use the current managed node group for the reference baseline and document **Karpenter as the preferred evaluation candidate once a live dev environment produces scheduling and cost data**. Do not install Karpenter merely to add another badge or component to the repository.

Activation criteria:

1. HPA regularly creates Pending pods because node capacity is exhausted
2. workload requests/limits have been observed under representative traffic
3. allowed instance families, architectures, purchase options, zones, and disruption budgets are explicitly defined
4. IAM and interruption handling are tested in dev
5. cost and recovery behavior are compared with Cluster Autoscaler using the same workload

This decision keeps the lab honest: workload autoscaling is implemented, node-autoscaling architecture is evaluated, but no unsupported claim is made that Karpenter is running.
