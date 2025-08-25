# Container-related reusable Makefile fragment.
# Include from the root Makefile: -include mk/container.mk
# Focus: Podman first; falls back to Docker if Podman unavailable.

# ---- Configurable knobs (override via env / make VAR=) ----
CONTAINER_ENGINE ?= $(shell command -v podman >/dev/null 2>&1 && echo podman || (command -v docker >/dev/null 2>&1 && echo docker || echo podman))
REGISTRY          ?= ghcr.io
IMAGE_ORG        ?= sunflower-works
IMAGE_NAME       ?= vision
# VERSION expected from parent Makefile; fall back to reading file if missing
VERSION           ?= $(shell grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' $(VERSION_FILE) 2>/dev/null || echo dev)
IMAGE_REPO       := $(REGISTRY)/$(IMAGE_ORG)/$(IMAGE_NAME)
IMAGE_TAG        ?= $(VERSION)
LATEST_TAG       ?= latest
PLATFORMS        ?= linux/amd64
BINARIES         ?= vision-cli thumbnailer
# Optional build metadata
BUILD_DATE       ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
GIT_SHA          ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)

# Common label block
OCI_LABELS = \
  --label org.opencontainers.image.title="$(IMAGE_NAME)" \
  --label org.opencontainers.image.version="$(IMAGE_TAG)" \
  --label org.opencontainers.image.created="$(BUILD_DATE)" \
  --label org.opencontainers.image.revision="$(GIT_SHA)" \
  --label org.opencontainers.image.source="https://github.com/$(IMAGE_ORG)/$(IMAGE_NAME)" \
  --label org.opencontainers.image.licenses="MIT"

# Determine supported buildx style multi-arch. Podman supports --platform natively; Docker needs buildx.
MULTI_ARCH_FLAG = $(if $(findstring podman,$(CONTAINER_ENGINE)),--platform=$(PLATFORMS),--platform $(PLATFORMS))

.PHONY: image-info image-build image-build-all image-build-multi image-run image-shell image-tag-latest image-push image-push-all image-sbom image-scan image-save image-load

image-info:
	@echo "Container engine: $(CONTAINER_ENGINE)"
	@echo "Image repo:       $(IMAGE_REPO)"
	@echo "Tag:             $(IMAGE_TAG)"
	@echo "Binaries:        $(BINARIES)"
	@echo "Platforms:       $(PLATFORMS)"

# Build a single image embedding one binary (default BIN=vision-cli)
image-build: BIN ?= vision-cli
image-build:
	@echo "==> Building image for $(BIN) using $(CONTAINER_ENGINE)"
	$(CONTAINER_ENGINE) build \
	  --file Containerfile \
	  --build-arg BIN=$(BIN) \
	  --build-arg VERSION=$(IMAGE_TAG) \
	  --build-arg BUILD_DATE=$(BUILD_DATE) \
	  --build-arg GIT_SHA=$(GIT_SHA) \
	  $(OCI_LABELS) \
	  -t $(IMAGE_REPO)-$(BIN):$(IMAGE_TAG) \
	  -t $(IMAGE_REPO)-$(BIN):$(LATEST_TAG) .

# Loop over BINARIES and build each separately
image-build-all:
	@set -e; for b in $(BINARIES); do \
	  echo "==> Building image for $$b"; \
	  $(MAKE) --no-print-directory image-build BIN=$$b; \
	done

# Multi-arch build (experimental). Requires qemu/binfmt installed for non-native arches.
image-build-multi: BIN ?= vision-cli
image-build-multi:
	@echo "==> Multi-arch build for $(BIN): $(PLATFORMS)"
	$(CONTAINER_ENGINE) build \
	  $(MULTI_ARCH_FLAG) \
	  --file Containerfile \
	  --build-arg BIN=$(BIN) \
	  --build-arg VERSION=$(IMAGE_TAG) \
	  --build-arg BUILD_DATE=$(BUILD_DATE) \
	  --build-arg GIT_SHA=$(GIT_SHA) \
	  $(OCI_LABELS) \
	  -t $(IMAGE_REPO)-$(BIN):$(IMAGE_TAG) \
	  -t $(IMAGE_REPO)-$(BIN):$(LATEST_TAG) .

image-run: BIN ?= vision-cli
image-run:
	@echo "==> Running $(IMAGE_REPO)-$(BIN):$(IMAGE_TAG)";
	$(CONTAINER_ENGINE) run --rm -it $(IMAGE_REPO)-$(BIN):$(IMAGE_TAG) $(ARGS)

image-shell: BIN ?= vision-cli
image-shell:
	$(CONTAINER_ENGINE) run --rm -it --entrypoint /bin/sh $(IMAGE_REPO)-$(BIN):$(IMAGE_TAG)

image-tag-latest: BIN ?= vision-cli
image-tag-latest:
	$(CONTAINER_ENGINE) tag $(IMAGE_REPO)-$(BIN):$(IMAGE_TAG) $(IMAGE_REPO)-$(BIN):$(LATEST_TAG)

image-push: BIN ?= vision-cli
image-push:
	$(CONTAINER_ENGINE) push $(IMAGE_REPO)-$(BIN):$(IMAGE_TAG)
	$(CONTAINER_ENGINE) push $(IMAGE_REPO)-$(BIN):$(LATEST_TAG)

image-push-all:
	@set -e; for b in $(BINARIES); do \
	  echo "==> Pushing $(IMAGE_REPO)-$$b"; \
	  $(MAKE) --no-print-directory image-push BIN=$$b; \
	done

# Produce a local SBOM using syft if available
image-sbom: BIN ?= vision-cli
image-sbom:
	@command -v syft >/dev/null 2>&1 || { echo "syft not installed"; exit 1; }
	syft $(IMAGE_REPO)-$(BIN):$(IMAGE_TAG)

# Vulnerability scan using grype if available
image-scan: BIN ?= vision-cli
image-scan:
	@command -v grype >/dev/null 2>&1 || { echo "grype not installed"; exit 1; }
	grype $(IMAGE_REPO)-$(BIN):$(IMAGE_TAG)

# Save and load helpers
image-save: BIN ?= vision-cli
image-save:
	$(CONTAINER_ENGINE) save $(IMAGE_REPO)-$(BIN):$(IMAGE_TAG) -o $(IMAGE_NAME)-$(BIN)-$(IMAGE_TAG).tar

image-load: FILE ?= image.tar
image-load:
	$(CONTAINER_ENGINE) load -i $(FILE)

