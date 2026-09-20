# Container Supply Chain

The repository contains a minimal Go service under `demo-app/` to demonstrate a build artifact that is owned by this project rather than relying only on a third-party sample image.

## Pipeline

```text
source
  │
  ├─ go test / go vet
  ▼
BuildKit
  │
  ├─ provenance attestation
  ├─ SBOM attestation
  ▼
GHCR image by immutable digest
  │
  ├─ Trivy HIGH/CRITICAL gate
  ▼
Cosign keyless signature
  │
  └─ GitHub OIDC identity recorded in certificate
```

The workflow never stores a Cosign private key. Sigstore keyless signing uses the GitHub Actions OIDC identity and publishes the signature alongside the OCI image.

## Image tags

The workflow publishes:

- `sha-<full-git-sha>` for traceability
- `main` for convenience on the default branch
- the Git tag when the workflow is triggered by a `v*` tag

Kubernetes should consume the **digest**, not the mutable `main` tag.

## Verify a signature

```bash
cosign verify \
  --certificate-identity-regexp 'https://github.com/fadyy2k/platform-engineering-eks-gitops/.github/workflows/image.yml@refs/(heads/main|tags/.*)' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
  ghcr.io/fadyy2k/platform-demo@sha256:<digest>
```

## Trust decision

An image is considered promotable only when all of these are true:

1. source tests pass
2. image build succeeds
3. Trivy reports no allowed-to-fail HIGH/CRITICAL gate violation
4. the image has BuildKit provenance/SBOM attestations
5. Cosign verification matches this repository's workflow identity
6. the Kubernetes manifest pins the approved digest

A later policy-as-code phase can enforce signature verification inside the cluster rather than relying only on the delivery workflow.
