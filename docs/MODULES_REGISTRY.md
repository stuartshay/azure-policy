# Terraform Cloud Private Module Registry Usage

This project uses the Terraform Cloud Private Module Registry for shared modules.

## Networking Module

Module path in repo: `infrastructure/terraform/modules/networking`

Published name (expected): `azure-policy-cloud/networking/azurerm`

### Publish Steps
1. Ensure repo is connected to Terraform Cloud VCS integration.
2. Tag the repository with a semantic version for the module (example):
   - `git tag -a networking-v0.1.0 -m "Networking module v0.1.0"`
   - `git push origin networking-v0.1.0`
   - (If required by org policy also push `v0.1.0`).
3. In Terraform Cloud: Registry -> Publish -> Select repository -> Specify subdirectory `infrastructure/terraform/modules/networking`.
4. Confirm the module appears with version `0.1.0`.
5. Update `variable "networking_module_version"` (in `infrastructure/core/variables.tf`) when releasing new versions.

### Upgrading
1. Create and push a new tag (e.g. `networking-v0.2.0`).
2. Wait for Terraform Cloud to ingest the version.
3. Change `networking_module_version` default (or override via tfvars) to `0.2.0`.
4. Run `make terraform-core-init` then `make terraform-core-plan` to review changes.

### Verification
Run:
```
make terraform-core-init
make terraform-core-plan
```
The init step should show it is downloading the registry module `azure-policy-cloud/networking/azurerm` at the specified version.

### Fallback
If the registry is temporarily unavailable, revert the module block in `core/main.tf` to the previous Git source URL pinned to a commit hash. Remember that dynamic switching of the `source` argument is not supported—manual edit required.

### Recommended Version Pinning Policy
Use `exact` or patch-compatible constraints:
* For stability: `version = "0.1.0"`
* For automatic patch updates later: change module block to use a constraint (e.g. `~> 0.1.0`) once module is stable.

---
Generated helper documentation for internal use.
