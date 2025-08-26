# Root Makefile for vision module
# Lightweight developer conveniences; CI uses central reusable workflows.

GOFILES := $(shell find . -name '*.go' -not -path './vendor/*')
PKG := ./...
MODULE := github.com/sunflower-works/vision
VERSION_FILE := pkg/vision/version/version.go

# Include optional container targets (Podman/Docker) if present
-include mk/container.mk

.PHONY: all proto generate test race cover lint vet fmt tidy ci release-check version bump-patch help bench

all: test

proto generate:
	@echo '==> Regenerating protobuf stubs'
	go generate ./pkg/vision/eye

lint vet:
	@echo '==> go vet'
	go vet $(PKG)

fmt:
	@echo '==> go fmt'
	go fmt $(PKG)

tidy:
	@echo '==> go mod tidy'
	go mod tidy

test:
	@echo '==> go test'
	go test -count=1 $(PKG)

race:
	@echo '==> go test -race'
	go test -race -count=1 $(PKG)

cover:
	@echo '==> coverage'
	go test -race -count=1 -covermode=atomic -coverprofile=coverage.out $(PKG)
	@go tool cover -func=coverage.out | tail -n1

ci: proto fmt vet tidy cover

version:
	@grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' $(VERSION_FILE)

release-check: proto vet test
	@echo '==> Ensuring working tree clean'
	@git diff --quiet || (echo 'ERROR: uncommitted changes'; exit 1)
	@echo '==> Version:' $(shell $(MAKE) --no-print-directory version)
	@echo '==> CHANGELOG head:'
	@head -n 20 CHANGELOG.md
	@echo 'Release check complete.'

# Convenience: bump patch version (requires semver, no pre-release logic)
bump-patch:
	@curr=$$(grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' $(VERSION_FILE)); \
	major=$$(echo $$curr|cut -d. -f1); minor=$$(echo $$curr|cut -d. -f2); patch=$$(echo $$curr|cut -d. -f3); \
	new=$${major}.$${minor}.$$((patch+1)); \
	sed -i "s/Version = \"$$curr\"/Version = \"$$new\"/" $(VERSION_FILE); \
	echo "Bumped $$curr -> $$new";

help:
	@echo 'Common targets:'
	@echo '  make test            Run tests'
	@echo '  make cover           Coverage'
	@echo '  make fmt vet tidy    Hygiene'
	@echo '  make bump-patch      Increment patch version'
	@echo '  make image-build BIN=vision-cli   Build CPU container (Podman/Docker)'
	@echo '  make image-build BIN=vision-cli GPU=1   Build GPU container (linux/amd64, CUDA)'
	@echo '  make image-run BIN=vision-cli ARGS="-h"  Run container binary'
	@echo '  make image-run BIN=vision-cli GPU=1      Run GPU container (requires nvidia toolkit)'
	@echo '  make image-build-all        Build images for all BINARIES (CPU)'
	@echo '  make image-build-all GPU=1  Build GPU images for all BINARIES'
	@echo '  make image-push-all         Push all CPU images'
	@echo '  make image-push-all GPU=1   Push all GPU images'
	@echo '  make bench           Run benchmarks'