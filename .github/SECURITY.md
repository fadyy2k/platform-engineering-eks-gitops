# Security Policy

This is a public platform-engineering lab. Production credentials, cloud account identifiers, private endpoints and customer data must never be committed.

## Reporting

Please use GitHub private vulnerability reporting when available. Otherwise use the contact link on my GitHub profile.

Do not open a public issue containing credentials, exploit details for a live system, private infrastructure identifiers, or confidential data.

## Repository controls

- Secret scanning and push protection are enabled.
- Dependabot tracks Terraform and GitHub Actions dependencies.
- CI performs secret and infrastructure-configuration scanning.
- Terraform variable files containing environment-specific values are ignored.
