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
# GPU variant controls
GPU ?= 0
CUDA_VERSION ?= 12.5.1
CUDA_IMAGE_FLAVOR ?= runtime-ubuntu22.04 # e.g. runtime-ubuntu22.04, devel-ubuntu22.04
GPU_BASE_IMAGE ?= nvidia/cuda:$(CUDA_VERSION)-$(CUDA_IMAGE_FLAVOR)
GPU_BUILDER_IMAGE ?= nvidia/cuda:$(CUDA_VERSION)-devel-ubuntu22.04
GO_VERSION ?= 1.24.0
GPU_FLAG := $(if $(filter 1 true yes,$(GPU)),1,0)
VARIANT_SUFFIX := $(if $(filter 1 true yes,$(GPU)),-gpu,)
# Optional build metadata
BUILD_DATE       ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
GIT_SHA          ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)
VISION_REF ?= main
GPU_CONTAINER_CONTEXT ?= ../vision-containers
CPU_CONTAINER_CONTEXT ?= ../vision-containers
# Detect external gpu containerfile if present
GPU_EXTERNAL_FILE := $(GPU_CONTAINER_CONTEXT)/Containerfile.gpu
GPU_CONTAINERFILE_PATH := $(if $(and $(filter 1,$(GPU_FLAG)),$(wildcard $(GPU_EXTERNAL_FILE))),$(GPU_EXTERNAL_FILE),$(CONTAINERFILE))
GPU_BUILD_CONTEXT := $(if $(and $(filter 1,$(GPU_FLAG)),$(wildcard $(GPU_EXTERNAL_FILE))),$(GPU_CONTAINER_CONTEXT),.)
CPU_EXTERNAL_FILE := $(CPU_CONTAINER_CONTEXT)/Containerfile.cpu
# Build-time selection for containerfile + context
BUILD_CONTAINERFILE_PATH := $(if $(filter 1,$(GPU_FLAG)),$(GPU_CONTAINERFILE_PATH),$(if $(wildcard $(CPU_EXTERNAL_FILE)),$(CPU_EXTERNAL_FILE),$(CONTAINERFILE)))
BUILD_CONTEXT := $(if $(filter 1,$(GPU_FLAG)),$(GPU_BUILD_CONTEXT),$(if $(wildcard $(CPU_EXTERNAL_FILE)),$(CPU_CONTAINER_CONTEXT),.))

# Select containerfile based on variant
CONTAINERFILE := $(if $(filter 1 true yes,$(GPU)),Containerfile.gpu,Containerfile)
# Image base name per binary + variant
IMG_BASE = $(IMAGE_REPO)-$(BIN)$(VARIANT_SUFFIX)

# Common label block (variant appended separately)
OCI_LABELS = \
  --label org.opencontainers.image.title="$(IMAGE_NAME)" \
  --label org.opencontainers.image.version="$(IMAGE_TAG)" \
  --label org.opencontainers.image.created="$(BUILD_DATE)" \
  --label org.opencontainers.image.revision="$(GIT_SHA)" \
  --label org.opencontainers.image.source="https://github.com/$(IMAGE_ORG)/$(IMAGE_NAME)" \
  --label org.opencontainers.image.licenses="MIT" \
  --label org.opencontainers.image.variant="$(if $(filter 1 true yes,$(GPU)),gpu,cpu)"

# Determine supported buildx style multi-arch. Podman supports --platform natively; Docker needs buildx.
MULTI_ARCH_FLAG = $(if $(findstring podman,$(CONTAINER_ENGINE)),--platform=$(PLATFORMS),--platform $(PLATFORMS))

# Enhanced engine check: verify binary present; if docker, verify daemon reachable.
ENGINE_CHECK = \
	command -v $(CONTAINER_ENGINE) >/dev/null 2>&1 || { echo "ERROR: container engine '$(CONTAINER_ENGINE)' not found"; exit 1; }; \
	if [ "$(CONTAINER_ENGINE)" = docker ]; then \
	  docker info >/dev/null 2>&1 || { echo "ERROR: docker CLI found but daemon unreachable. Start docker or set CONTAINER_ENGINE=podman"; exit 1; }; \
	fi

# GPU build args (conditionally appended)
GPU_BUILD_ARGS = $(if $(filter 1 true yes,$(GPU)),--build-arg CUDA_VERSION=$(CUDA_VERSION) --build-arg CUDA_IMAGE_FLAVOR=$(CUDA_IMAGE_FLAVOR) --build-arg GPU_BASE_IMAGE=$(GPU_BASE_IMAGE) --build-arg GPU_BUILDER_IMAGE=$(GPU_BUILDER_IMAGE) --build-arg GO_VERSION=$(GO_VERSION) --build-arg GPU=1,)

.PHONY: image-info image-build image-build-all image-build-multi image-run image-shell image-tag-latest image-push image-push-all image-sbom image-scan image-save image-load container-engine-check

container-engine-check:
	@$(ENGINE_CHECK)
	@echo "Engine $(CONTAINER_ENGINE) OK"

image-info:
	@echo "Container engine: $(CONTAINER_ENGINE)"
	@echo "Image repo:       $(IMAGE_REPO)"
	@echo "Tag:             $(IMAGE_TAG)"
	@echo "Binaries:        $(BINARIES)"
	@echo "Platforms:       $(PLATFORMS)"
	@echo "Variant (GPU?):  $(if $(filter 1,$(GPU_FLAG)),gpu,cpu)"
	@echo "Containerfile:   $(CONTAINERFILE)"
	@if [ $(GPU_FLAG) -eq 1 ]; then echo "CUDA base (runtime): $(GPU_BASE_IMAGE)"; echo "CUDA builder:      $(GPU_BUILDER_IMAGE)"; fi

# Build a single image embedding one binary (default BIN=vision-cli)
image-build: BIN ?= vision-cli
image-build:
	@$(ENGINE_CHECK)
	@if [ $(GPU_FLAG) -eq 1 ] && [ "$(PLATFORMS)" != "linux/amd64" ]; then echo "ERROR: GPU variant currently limited to linux/amd64"; exit 1; fi
	@echo "==> Building image for $(BIN) variant=$(if $(filter 1,$(GPU_FLAG)),gpu,cpu) using $(CONTAINER_ENGINE)"
	@echo "    Containerfile: $(BUILD_CONTAINERFILE_PATH) (context: $(BUILD_CONTEXT))"
	DOCKER_BUILDKIT=1 $(CONTAINER_ENGINE) build \
	  --file $(BUILD_CONTAINERFILE_PATH) \
	  --build-arg BIN=$(BIN) \
	  --build-arg VERSION=$(IMAGE_TAG) \
	  --build-arg BUILD_DATE=$(BUILD_DATE) \
	  --build-arg GIT_SHA=$(GIT_SHA) \
	  --build-arg VISION_REF=$(VISION_REF) \
	  $(GPU_BUILD_ARGS) \
	  $(OCI_LABELS) \
	  -t $(IMG_BASE):$(IMAGE_TAG) \
	  -t $(IMG_BASE):$(LATEST_TAG) $(BUILD_CONTEXT)

# Loop over BINARIES and build each separately
image-build-all:
	@$(ENGINE_CHECK)
	@set -e; for b in $(BINARIES); do \
	  echo "==> Building image for $$b (variant=$(if $(filter 1,$(GPU_FLAG)),gpu,cpu))"; \
	  $(MAKE) --no-print-directory image-build BIN=$$b GPU=$(GPU); \
	done

# Multi-arch build (experimental). Requires qemu/binfmt installed for non-native arches.
image-build-multi: BIN ?= vision-cli
image-build-multi:
	@$(ENGINE_CHECK)
	@if [ $(GPU_FLAG) -eq 1 ]; then echo "ERROR: multi-arch build for GPU variant not enabled"; exit 1; fi
	@echo "==> Multi-arch build for $(BIN): $(PLATFORMS)"
	DOCKER_BUILDKIT=1 $(CONTAINER_ENGINE) build \
	  $(MULTI_ARCH_FLAG) \
	  --file $(CONTAINERFILE) \
	  --build-arg BIN=$(BIN) \
	  --build-arg VERSION=$(IMAGE_TAG) \
	  --build-arg BUILD_DATE=$(BUILD_DATE) \
	  --build-arg GIT_SHA=$(GIT_SHA) \
	  $(OCI_LABELS) \
	  -t $(IMG_BASE):$(IMAGE_TAG) \
	  -t $(IMG_BASE):$(LATEST_TAG) .

image-run: BIN ?= vision-cli
# GPU run options differ per engine
GPU_RUN_OPTS_DOCKER ?= --gpus all
GPU_RUN_OPTS_PODMAN ?= # Provide explicit --device flags if needed
GPU_RUN_OPTS = $(if $(filter 1,$(GPU_FLAG)),$(if $(findstring docker,$(CONTAINER_ENGINE)),$(GPU_RUN_OPTS_DOCKER),$(GPU_RUN_OPTS_PODMAN)),)
image-run:
	@$(ENGINE_CHECK)
	@echo "==> Running $(IMG_BASE):$(IMAGE_TAG) (variant=$(if $(filter 1,$(GPU_FLAG)),gpu,cpu))";
	$(CONTAINER_ENGINE) run --rm -it $(GPU_RUN_OPTS) $(IMG_BASE):$(IMAGE_TAG) $(ARGS)

image-shell: BIN ?= vision-cli
image-shell:
	@$(ENGINE_CHECK)
	$(CONTAINER_ENGINE) run --rm -it $(GPU_RUN_OPTS) --entrypoint /bin/sh $(IMG_BASE):$(IMAGE_TAG)

image-tag-latest: BIN ?= vision-cli
image-tag-latest:
	@$(ENGINE_CHECK)
	$(CONTAINER_ENGINE) tag $(IMG_BASE):$(IMAGE_TAG) $(IMG_BASE):$(LATEST_TAG)

image-push: BIN ?= vision-cli
image-push:
	@$(ENGINE_CHECK)
	$(CONTAINER_ENGINE) push $(IMG_BASE):$(IMAGE_TAG)
	$(CONTAINER_ENGINE) push $(IMG_BASE):$(LATEST_TAG)

image-push-all:
	@$(ENGINE_CHECK)
	@set -e; for b in $(BINARIES); do \
	  echo "==> Pushing $(IMAGE_REPO)-$$b$(VARIANT_SUFFIX)"; \
	  $(MAKE) --no-print-directory image-push BIN=$$b GPU=$(GPU); \
	done

# Produce a local SBOM using syft if available
image-sbom: BIN ?= vision-cli
image-sbom:
	@command -v syft >/dev/null 2>&1 || { echo "syft not installed"; exit 1; }
	syft $(IMG_BASE):$(IMAGE_TAG)

# Vulnerability scan using grype if available
image-scan: BIN ?= vision-cli
image-scan:
	@command -v grype >/dev/null 2>&1 || { echo "grype not installed"; exit 1; }
	grype $(IMG_BASE):$(IMAGE_TAG)

# Save and load helpers
image-save: BIN ?= vision-cli
image-save:
	@$(ENGINE_CHECK)
	$(CONTAINER_ENGINE) save $(IMG_BASE):$(IMAGE_TAG) -o $(IMAGE_NAME)-$(BIN)$(VARIANT_SUFFIX)-$(IMAGE_TAG).tar

image-load: FILE ?= image.tar
image-load:
	@$(ENGINE_CHECK)
	$(CONTAINER_ENGINE) load -i $(FILE)
