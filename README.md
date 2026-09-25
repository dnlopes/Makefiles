# Makefiles

Reusable GNU Make targets that you include in other repositories. Each vertical, such as Terraform, is one `.mk` file with a documented public API. That API is a set of variables you set and targets you call.

## Requirements

- GNU Make 3.81 or later. macOS ships 3.81, so the files avoid features from 3.82 and 4.x.
- A POSIX `sh`. The files do not change `SHELL`, so your own recipes keep the shell you choose.

## Add the repository to a project

To add this repository as a Git submodule at `.makefiles`, run:

```bash
git submodule add https://github.com/dnlopes/Makefiles.git .makefiles
```

Clone projects that use it with `git clone --recurse-submodules`. In CI, enable recursive submodule checkout.

To update to a newer version, run:

```bash
git submodule update --remote .makefiles
```

## Use a vertical

Include the vertical in your `Makefile`, set the variables you need, and call the targets:

```make
TERRAFORM_DIR       := terraform
TERRAFORM_WORKSPACE := my-project-dev
include .makefiles/terraform.mk

export AWS_PROFILE := my-profile
```

Then run:

```bash
make                                      # lists targets
make tf-plan TERRAFORM_VAR_FILES=configs/dev.tfvars
make tf-apply TERRAFORM_AUTO_APPROVE=true
```

### Conventions

These rules apply to every vertical:

- Public variables are uppercase and use the vertical's prefix, for example `TERRAFORM_DIR`. Lowercase variables are internal and can change without notice.
- Public targets use the vertical's prefix and dashes, for example `tf-plan`.
- Every public variable has a default set with `?=`. Command-line values override values in your `Makefile`, and your `Makefile` overrides the environment.
- Boolean variables accept only `true` or `false`. Any other value stops make with an error.
- Targets that run commands also accept a `*_ARGS` variable. Use it to pass flags that the vertical does not expose.

### Set the default goal

`make` with no target runs `help`. To run a different target by default, set `.DEFAULT_GOAL` after the include:

```make
include .makefiles/terraform.mk
.DEFAULT_GOAL := tf-plan
```

### Extend a target

To run your own step before a shared target, add a prerequisite to the target. Do not add a recipe:

```make
tf-plan: check-credentials

check-credentials:
	aws sts get-caller-identity
```

To give a shared target a project name, create an alias. The alias appears in `make help` when you add a `##` description:

```make
deploy: tf-apply ## Deploy the infrastructure
```

To list your own targets under a heading in `make help`, add a `##@ Heading` line above them.

Do not define a recipe for a shared target. Make keeps the last recipe it reads and prints `warning: overriding commands for target`.

## Terraform (`terraform.mk`)

`terraform.mk` runs Terraform against one root module. It requires Terraform 1.4 or later. To use OpenTofu, set `TERRAFORM_BIN=tofu`. To list its targets, run `make help`.

### Terraform variables

| Variable | Default | Description |
| --- | --- | --- |
| `TERRAFORM_BIN` | `terraform` | Terraform executable. |
| `TERRAFORM_DIR` | `.` | Root module directory, passed to `-chdir`. |
| `TERRAFORM_WORKSPACE` | (empty) | Workspace to select, created if missing. If empty, the targets do not touch workspaces. |
| `TERRAFORM_VAR_FILES` | (empty) | Space-separated `.tfvars` files for `plan`, `apply`, and `destroy`. If empty, no `-var-file` flag is passed. |
| `TERRAFORM_AUTO_APPROVE` | `false` | If `true`, adds `-auto-approve` to `apply` and `destroy`. |
| `TERRAFORM_INIT_ARGS` | (empty) | Extra flags for `init`, for example `-backend-config=backend.hcl`. |
| `TERRAFORM_PLAN_ARGS` | (empty) | Extra flags for `plan`, for example `-lock=false`. |
| `TERRAFORM_APPLY_ARGS` | (empty) | Extra flags for `apply`. |
| `TERRAFORM_DESTROY_ARGS` | (empty) | Extra flags for `destroy`. |
| `TERRAFORM_LOCK_PLATFORMS` | `linux_amd64 linux_arm64 darwin_amd64 darwin_arm64 windows_amd64` | Platforms that `tf-lock` records in `.terraform.lock.hcl`. |

Terraform runs with `-chdir=$(TERRAFORM_DIR)`, so it resolves relative paths in `TERRAFORM_VAR_FILES` and `TERRAFORM_*_ARGS` against `TERRAFORM_DIR`. It does not resolve them against the directory where you run `make`.

The variables use the `TERRAFORM_` prefix, not `TF_`. Terraform reads `TF_*` environment variables itself. For example, `TF_WORKSPACE` overrides workspace selection.
