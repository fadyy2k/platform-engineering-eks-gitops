# Contributing

This repository is a public platform-engineering reference. Contributions should improve a control, test, operational decision or piece of reproducible evidence—not add technology only to make the architecture larger.

## Change flow

1. Create a focused branch.
2. Keep cloud/environment-specific values out of Git.
3. Run the relevant local checks.
4. Open a pull request explaining the engineering reason, failure mode and validation performed.
5. Merge only after required CI/security checks pass.

## Local checks

```bash
make fmt
make validate
make k8s-check
make demo-test
make policy-test
make reliability-test
make operations-test
./scripts/preflight.sh --local
```

## Design changes

Open an ADR when a change introduces a meaningful long-lived trade-off such as identity model, cluster/network topology, autoscaling strategy, state model, multi-region behavior or a new trust boundary.

A design PR should answer:

- What problem/failure mode is being addressed?
- What alternatives were considered?
- What new privilege, cost or operational burden is introduced?
- How is rollback performed?
- What evidence proves the change works?

## Security and privacy

Never commit:

- AWS account IDs or role ARNs from a private account;
- access keys, tokens or kubeconfigs;
- private IP plans/endpoints from a real environment;
- customer/company identifiers that are not already intentionally public;
- screenshots containing credentials or administrative URLs.

Use synthetic/sanitized values in public evidence.

## Live changes

Terraform apply, game-day execution, backup/restore tests and Argo bootstrap are environment mutations. They require an explicitly approved non-production target and should follow [docs/LIVE_ACTIVATION.md](docs/LIVE_ACTIVATION.md).
