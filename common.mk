# common.mk: helpers shared by every vertical. Verticals include it; consumers do not need to.
#
# Public API
#
#   Targets
#     help                        List every target annotated with "## description" across all included
#                                 makefiles, grouped by "##@ Section" lines.
#
#   Variables (set them in your Makefile, in the environment, or on the command line)
#     TOOLS                       Go tools to install, as space-separated NAME=MODULE@VERSION entries,
#                                 for example "mockery=github.com/vektra/mockery/v2@v2.46.0". NAME is the
#                                 binary that `go install` produces. Prefer a fixed VERSION over "latest":
#                                 changing an entry reinstalls that tool, but "latest" is never rechecked.
#                                                                                         Default: (empty)
#     TOOLS_DIR                   Where the tools are installed. Set it before the include.
#                                                                                         Default: $(CURDIR)/bin
#     GO_BIN                      Go executable used to install the tools.                Default: go
#
#   Targets
#     tools                       Install every tool in TOOLS that is missing or out of date.
#     tools-clean                 Remove the installed tools. Other files in TOOLS_DIR are kept.
#
#   Functions
#     $(call mk-bool,VAR,VALUE)   Expand to VALUE when $(VAR) is "true" and to nothing when it is "false".
#                                 Any other value stops make with an error.
#     $(call mk-tool,NAME)        Expand to the absolute path of tool NAME, an error if NAME is not in TOOLS.
#                                 Use it as a prerequisite to install the tool on demand, and in the recipe to
#                                 run it:
#                                   go-mocks: $(call mk-tool,mockery)
#                                   	$(call mk-tool,mockery)
#
#   Behaviour
#     Sets .DEFAULT_GOAL to help, unless a target was defined before the first include.

ifndef mk_common_included
mk_common_included := 1

ifeq ($(.DEFAULT_GOAL),)
.DEFAULT_GOAL := help
endif

TOOLS     ?=
TOOLS_DIR ?= $(CURDIR)/bin
GO_BIN    ?= go

mk-bool = $(if $(filter true,$(strip $($(1)))),$(2),$(if $(filter false,$(strip $($(1)))),,$(error $(1) must be "true" or "false", got "$($(1))")))

##@ General
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m [VARIABLE=value ...]\n"} \
		FNR == 1 { skip = seen[FILENAME]++ } skip { next } \
		/^[a-zA-Z_0-9-]+:.*##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

tools_dir      := $(abspath $(TOOLS_DIR))
tool_names      = $(foreach t,$(TOOLS),$(firstword $(subst =, ,$(t))))
tool_spec       = $(patsubst $(1)=%,%,$(filter $(1)=%,$(TOOLS)))
tool_spec_valid = $(if $(findstring @,$(call tool_spec,$(1))),$(call tool_spec,$(1)),$(error TOOLS must declare "$(1)" as $(1)=MODULE@VERSION))

mk-tool = $(if $(filter $(1),$(tool_names)),$(tools_dir)/$(1),$(error "$(1)" is not declared in TOOLS))

##@ Tools
tools: ## Install the tools declared in TOOLS
	@$(if $(tool_names),$(MAKE) --no-print-directory -f $(firstword $(MAKEFILE_LIST)) $(addprefix $(tools_dir)/,$(tool_names)),echo "TOOLS is empty")

tools-clean: ## Remove the tools declared in TOOLS
	rm -rf $(addprefix $(tools_dir)/,$(tool_names)) $(tools_dir)/.spec

# The spec file changes only when a tool's declaration does, so the binary rebuilds on a version bump and not otherwise.
$(tools_dir)/.spec/%: tools-force
	@mkdir -p $(@D)
	@printf '%s\n' '$(call tool_spec_valid,$*)' | cmp -s - $@ || printf '%s\n' '$(call tool_spec_valid,$*)' > $@

$(tools_dir)/%: $(tools_dir)/.spec/%
	@echo "Installing $* ($(call tool_spec_valid,$*))"
	@GOBIN=$(tools_dir) $(GO_BIN) install $(call tool_spec_valid,$*)
	@[ -f $@ ] || { echo "go install produced no $(@F) binary: NAME in TOOLS must match the binary name" >&2; exit 1; }

.PRECIOUS: $(tools_dir)/.spec/%
.PHONY: help tools tools-clean tools-force

endif
