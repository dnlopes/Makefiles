# terraform.mk: targets for a single Terraform root module. Works with OpenTofu through TERRAFORM_BIN.
#
# Usage
#   include path/to/terraform.mk
#
# Public API
#
#   Variables (set them in your Makefile, in the environment, or on the command line)
#     TERRAFORM_BIN            Terraform executable.                                     Default: terraform
#     TERRAFORM_DIR            Root module directory, passed to -chdir.                  Default: .
#     TERRAFORM_WORKSPACE      Workspace to select, created if missing. Empty: the
#                              targets do not touch workspaces.                          Default: (empty)
#     TERRAFORM_VAR_FILES      Space-separated .tfvars files for plan, apply, and
#                              destroy. Relative paths resolve against TERRAFORM_DIR,
#                              because of -chdir. Empty: no -var-file flag.              Default: (empty)
#     TERRAFORM_AUTO_APPROVE   "true" adds -auto-approve to apply and destroy.           Default: false
#     TERRAFORM_INIT_ARGS      Extra flags for init, for example -backend-config=...     Default: (empty)
#     TERRAFORM_PLAN_ARGS      Extra flags for plan, for example -lock=false.            Default: (empty)
#     TERRAFORM_APPLY_ARGS     Extra flags for apply.                                    Default: (empty)
#     TERRAFORM_DESTROY_ARGS   Extra flags for destroy.                                  Default: (empty)
#     TERRAFORM_LOCK_PLATFORMS Platforms recorded by tf-lock.                            Default: linux_amd64
#                                                                                        linux_arm64 darwin_amd64
#                                                                                        darwin_arm64 windows_amd64
#
#   Targets: run `make help`.
#
#   Requires Terraform >= 1.4 (for `workspace select -or-create`).

terraform_mk_dir := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
include $(terraform_mk_dir)/common.mk

TERRAFORM_BIN            ?= terraform
TERRAFORM_DIR            ?= .
TERRAFORM_WORKSPACE      ?=
TERRAFORM_VAR_FILES      ?=
TERRAFORM_AUTO_APPROVE   ?= false
TERRAFORM_INIT_ARGS      ?=
TERRAFORM_PLAN_ARGS      ?=
TERRAFORM_APPLY_ARGS     ?=
TERRAFORM_DESTROY_ARGS   ?=
TERRAFORM_LOCK_PLATFORMS ?= linux_amd64 linux_arm64 darwin_amd64 darwin_arm64 windows_amd64

terraform                   = $(TERRAFORM_BIN) -chdir=$(TERRAFORM_DIR)
terraform_var_file_args     = $(addprefix -var-file=,$(TERRAFORM_VAR_FILES))
terraform_auto_approve_arg  = $(call mk-bool,TERRAFORM_AUTO_APPROVE,-auto-approve)

##@ Terraform
tf-init: ## Initialise the root module
	$(terraform) init $(TERRAFORM_INIT_ARGS)

tf-workspace: tf-init ## Select TERRAFORM_WORKSPACE, creating it if missing
	$(if $(strip $(TERRAFORM_WORKSPACE)),$(terraform) workspace select -or-create $(TERRAFORM_WORKSPACE))

tf-fmt: ## Rewrite Terraform files to canonical format
	$(terraform) fmt -recursive

tf-lint: tf-init ## Check formatting and validate the configuration
	$(terraform) fmt -recursive -check
	$(terraform) validate

tf-plan: tf-workspace ## Show the changes Terraform would make
	$(terraform) plan $(terraform_var_file_args) $(TERRAFORM_PLAN_ARGS)

tf-apply: tf-workspace ## Apply changes (TERRAFORM_AUTO_APPROVE=true skips the prompt)
	$(terraform) apply $(terraform_var_file_args) $(terraform_auto_approve_arg) $(TERRAFORM_APPLY_ARGS)

tf-destroy: tf-workspace ## Destroy all resources (TERRAFORM_AUTO_APPROVE=true skips the prompt)
	$(terraform) destroy $(terraform_var_file_args) $(terraform_auto_approve_arg) $(TERRAFORM_DESTROY_ARGS)

tf-lock: tf-init ## Record provider checksums for TERRAFORM_LOCK_PLATFORMS
	$(terraform) providers lock $(addprefix -platform=,$(TERRAFORM_LOCK_PLATFORMS))

.PHONY: tf-init tf-workspace tf-fmt tf-lint tf-plan tf-apply tf-destroy tf-lock
