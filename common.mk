# common.mk: helpers shared by every vertical. Verticals include it; consumers do not need to.
#
# Public API
#
#   Targets
#     help                        List every target annotated with "## description" across all included
#                                 makefiles, grouped by "##@ Section" lines.
#
#   Functions
#     $(call mk-bool,VAR,VALUE)   Expand to VALUE when $(VAR) is "true" and to nothing when it is "false".
#                                 Any other value stops make with an error.
#
#   Behaviour
#     Sets .DEFAULT_GOAL to help, unless a target was defined before the first include.

ifndef mk_common_included
mk_common_included := 1

ifeq ($(.DEFAULT_GOAL),)
.DEFAULT_GOAL := help
endif

mk-bool = $(if $(filter true,$(strip $($(1)))),$(2),$(if $(filter false,$(strip $($(1)))),,$(error $(1) must be "true" or "false", got "$($(1))")))

##@ General
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m [VARIABLE=value ...]\n"} \
		/^[a-zA-Z_0-9-]+:.*##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

.PHONY: help

endif
