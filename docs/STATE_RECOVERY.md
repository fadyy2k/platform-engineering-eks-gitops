# Terraform State Recovery

The remote-state bucket is versioned and encrypted with a customer-managed KMS key. `force_destroy` is disabled.

## Accidental state object change or deletion

1. stop all Terraform plan/apply jobs for the affected environment
2. identify the state key, for example `platform/prod/terraform.tfstate`
3. inspect S3 object versions and select the last known-good version
4. restore that version as the current object
5. run `terraform plan -refresh-only` and review every proposed change
6. resume normal plans only after the state/resource relationship is understood

Do not blindly run `terraform apply` to “repair” state.

## Stale lock file

S3 native locking uses a `.tflock` object. If Terraform reports a lock:

1. confirm no plan/apply job is active
2. inspect the lock metadata / job history
3. use `terraform force-unlock <LOCK_ID>` only when the original operation is definitely gone

Deleting lock objects manually should be a last resort.

## KMS key safety

KMS key rotation is enabled and deletion uses a 30-day waiting period. Removing access to the KMS key makes encrypted state unreadable even if the S3 object still exists.

## Disaster-recovery extension

For a real platform, evaluate cross-region S3 replication, a separately controlled backup account, and periodic state-recovery exercises. Those controls are intentionally not enabled automatically in this lab because they add account topology and cost assumptions.
