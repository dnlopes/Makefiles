# golang.mk: targets for a single Go module.
#
# Usage
#   include path/to/golang.mk
#
# Public API
#
#   Variables (set them in your Makefile, in the environment, or on the command line)
#     GO_BIN                 Go executable.                                            Default: go
#     GO_DIR                 Module directory. Every command runs from here, so
#                            relative paths below resolve against it.                  Default: .
#     GO_BUILD_PKG           Package that go-build compiles.                           Default: .
#     GO_BUILD_OUTPUT        go-build output path. A trailing "/" names the binary
#                            after the package.                                        Default: $(CURDIR)/bin/
#     GO_BUILD_OS            GOOS for go-build only. Empty: the host OS.               Default: (empty)
#     GO_BUILD_ARCH          GOARCH for go-build only. Empty: the host architecture.   Default: (empty)
#     GO_BUILD_CGO_ENABLED   CGO_ENABLED ("0" or "1") for go-build only. Empty:
#                            inherited from the environment.                           Default: (empty)
#     GO_BUILD_FLAGS         Extra flags for go build, for example -trimpath.          Default: (empty)
#     GO_TEST_PKGS           Packages that go-test runs.                               Default: ./...
#     GO_TEST_FLAGS          Extra flags for go test, for example -v -race.            Default: (empty)
#     GO_COVER_PROFILE       Coverage profile that go-test writes. Empty: no
#                            coverage.                                                 Default: cover.out
#     GO_COVER_HTML          HTML report that go-cover-html writes.                    Default: cover.html
#
#   Targets: run `make help`.

golang_mk_dir := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
include $(golang_mk_dir)/common.mk

GO_BIN               ?= go
GO_DIR               ?= .
GO_BUILD_PKG         ?= .
GO_BUILD_OUTPUT      ?= $(CURDIR)/bin/
GO_BUILD_OS          ?=
GO_BUILD_ARCH        ?=
GO_BUILD_CGO_ENABLED ?=
GO_BUILD_FLAGS       ?=
GO_TEST_PKGS         ?= ./...
GO_TEST_FLAGS        ?=
GO_COVER_PROFILE     ?= cover.out
GO_COVER_HTML        ?= cover.html

# gofmt from GO_BIN's GOROOT, so formatting matches the selected toolchain rather than whichever gofmt is on PATH.
golang_gofmt     = "$$($(GO_BIN) env GOROOT)/bin/gofmt"
golang_build_env = $(if $(GO_BUILD_OS),GOOS=$(GO_BUILD_OS)) $(if $(GO_BUILD_ARCH),GOARCH=$(GO_BUILD_ARCH)) $(if $(GO_BUILD_CGO_ENABLED),CGO_ENABLED=$(GO_BUILD_CGO_ENABLED))

##@ Go
go-fmt: ## Rewrite Go files with gofmt -s
	cd $(GO_DIR) && $(golang_gofmt) -s -w .

go-tidy: ## Add missing and remove unused module requirements
	cd $(GO_DIR) && $(GO_BIN) mod tidy

go-lint: ## Check gofmt -s formatting and run go vet
	@cd $(GO_DIR) && files=$$($(golang_gofmt) -s -l .) && if [ -n "$$files" ]; then \
		echo "These files need formatting (run make go-fmt):"; echo "$$files"; exit 1; \
	fi
	cd $(GO_DIR) && $(GO_BIN) vet ./...

go-test: ## Run tests, writing GO_COVER_PROFILE when set
	cd $(GO_DIR) && $(GO_BIN) test $(GO_TEST_FLAGS) $(if $(GO_COVER_PROFILE),-coverprofile=$(GO_COVER_PROFILE)) $(GO_TEST_PKGS)

go-cover-html: go-test ## Run tests and render the coverage profile as HTML
	$(if $(GO_COVER_PROFILE),,$(error GO_COVER_PROFILE must be set for go-cover-html))
	cd $(GO_DIR) && $(GO_BIN) tool cover -html=$(GO_COVER_PROFILE) -o $(GO_COVER_HTML)

go-build: ## Build GO_BUILD_PKG into GO_BUILD_OUTPUT
	cd $(GO_DIR) && $(golang_build_env) $(GO_BIN) build $(GO_BUILD_FLAGS) -o $(GO_BUILD_OUTPUT) $(GO_BUILD_PKG)

.PHONY: go-fmt go-tidy go-lint go-test go-cover-html go-build
