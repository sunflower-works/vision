# sunflower-vision

[![CI](https://github.com/sunflower-works/vision/actions/workflows/ci.yml/badge.svg)](https://github.com/sunflower-works/vision/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/badge/coverage-auto--generated-blue)](https://github.com/sunflower-works/vision/actions/workflows/ci.yml)
[![API Stability](https://img.shields.io/badge/api%20stability-experimental-yellow)](#api-stability)

A small, composable computer vision toolkit that complements the sunflower SDK.

- Public API under `pkg/vision` (capture, pipeline, model, draw)
- Demo binaries in `cmd/`

Quick start:

```bash
# From repo root
# Run the demo CLI (synthetic source by default)
go run ./cmd/vision-cli
# Write a thumbnail from the first frame
go run ./cmd/thumbnailer -out /tmp/thumb.jpg
```

This uses a synthetic source by default (animated bar). Use `-src` for a file or camera id (to be wired later).

## Layout

- cmd/: CLI demo binaries
- pkg/vision/capture: sources (synthetic now; registry for future backends)
- pkg/vision/pipeline: simple processing graph + processor registry
- pkg/vision/model, draw, version: stubs / public API surfaces

## API Stability
Status: Experimental (< v1.0.0). Interfaces may change. Planned future extraction into a smaller `vision-core` module; see split plan (if present) or central roadmap.

## Containers (Podman / Docker)
A modular container build system is provided via `mk/container.mk` and the root `Makefile`.
Podman is preferred; Docker is used automatically if Podman is not found.

Images are built per binary (e.g. `vision-cli`, `thumbnailer`) and tagged with the module version (from `pkg/vision/version/version.go`) and `latest`.

Common commands:
```bash
# Show settings (engine, repo, version)
make image-info

# Build image for the demo CLI (defaults BIN=vision-cli)
make image-build
# Or explicitly
make image-build BIN=vision-cli

# Build image for thumbnailer
make image-build BIN=thumbnailer

# Build all declared binaries (BINARIES variable in mk/container.mk)
make image-build-all

# Run a built image (pass CLI args via ARGS="...")
make image-run BIN=vision-cli ARGS="-h"

# Open a shell inside the image
make image-shell BIN=vision-cli

# Multi-arch (set PLATFORMS, requires emulation / buildx)
PLATFORMS=linux/amd64,linux/arm64 make image-build-multi BIN=vision-cli

# Push a single image (requires registry auth; defaults to ghcr.io)
make image-push BIN=vision-cli

# Push all images
make image-push-all

# Generate SBOM (requires syft)
make image-sbom BIN=vision-cli

# Vulnerability scan (requires grype)
make image-scan BIN=vision-cli
```

Override defaults:
```bash
# Use a different registry / org
REGISTRY=registry.example.com IMAGE_ORG=myteam make image-build
# Custom tag (otherwise the version file semver is used)
IMAGE_TAG=v0.1.1-rc1 make image-build
```

Artifacts:
- `Containerfile` implements a minimal two-stage build producing a static binary in `scratch`.
- `.containerignore` trims build context for faster, reproducible builds.
- Version is injected with `-ldflags -X` (variable `version.Version`).

### GPU Variant
GPU-enabled images are available via a separate CUDA-based build path.

Key points:
- Trigger with `GPU=1` (e.g. `make image-build GPU=1 BIN=vision-cli`).
- Uses `Containerfile.gpu` and NVIDIA CUDA base images (runtime + devel for build stage).
- Only builds for `linux/amd64` currently (enforced in Makefile).
- Does NOT package kernel drivers; relies on NVIDIA Container Toolkit (Docker) or equivalent device pass-through (Podman).
- Image tag pattern: `ghcr.io/sunflower-works/vision-<bin>-gpu:<version>`.
- Labels include `org.opencontainers.image.variant=gpu`.

Recommended engines:
- Use Docker for GPU workflows (mature NVIDIA toolkit integration, profiling support).
- Podman may work for basic execution but can lag on advanced tooling; set `CONTAINER_ENGINE=podman` explicitly if desired.

Environment variables (override at build time):
- `CUDA_VERSION` (default 12.5.1)
- `CUDA_IMAGE_FLAVOR` (default runtime-ubuntu22.04)
- `GPU_BASE_IMAGE`, `GPU_BUILDER_IMAGE` (auto-derived; override if needed)

Examples:
```bash
# Build GPU image for vision-cli
make image-build GPU=1 BIN=vision-cli

# Run with all GPUs (Docker)
make image-run GPU=1 BIN=vision-cli ARGS="-h"
# Equivalent raw docker invocation after build
# docker run --rm --gpus all ghcr.io/sunflower-works/vision-vision-cli-gpu:$(make -s version) -h

# Build and push all GPU images
make image-build-all GPU=1
make image-push-all  GPU=1

# Specify a different CUDA version
CUDA_VERSION=12.4.1 make image-build GPU=1 BIN=thumbnailer
```

Limitations / roadmap:
- Multi-arch GPU builds (arm64) deferred until stable upstream CUDA arm64 publication.
- SBOM & vulnerability scan commands (`image-sbom`, `image-scan`) also work with `GPU=1`.
- Later: potential migration to buildkitd / nerdctl or ko for pure CPU paths while keeping GPU path stable.

Troubleshooting:
- If Docker daemon unreachable: start it or run `CONTAINER_ENGINE=podman make image-build` (CPU only or experimental GPU support).
- Ensure NVIDIA toolkit installed: `nvidia-smi` should work on host and `docker run --rm --gpus all nvidia/cuda:12.5.1-runtime-ubuntu22.04 nvidia-smi` should succeed.

### External Container Contexts
The build system can optionally source Containerfiles from an external directory (default `../vision-containers`) to decouple container packaging from core code changes.

Auto-detection precedence (per variant):
1. GPU build (GPU=1): use `../vision-containers/Containerfile.gpu` if it exists; otherwise fallback to in-repo `Containerfile.gpu` (if present) else error.
2. CPU build (GPU=0): use `../vision-containers/Containerfile.cpu` if it exists; otherwise fallback to in-repo `Containerfile`.

Key Makefile variables:
- `VISION_REF` (default: `main`) – Git ref (tag/branch/commit) for external builds that clone the repo inside the Containerfile.
- `GPU_CONTAINER_CONTEXT` / `CPU_CONTAINER_CONTEXT` – Override path to external context (default `../vision-containers`).
- `GPU=1` – Select GPU variant.

When an external context is used, the build context sent to the engine is that external directory (not the core repo). The Containerfile itself performs a shallow clone of the core repo at `VISION_REF` ensuring reproducible builds independent of local uncommitted changes.

Examples:
```bash
# CPU image from external context pinning a tag
make image-build BIN=vision-cli VISION_REF=v0.1.0 IMAGE_TAG=v0.1.0

# GPU image from external context pinning a tag
docker info >/dev/null 2>&1 || echo 'Docker daemon needed for GPU build'
make image-build GPU=1 BIN=vision-cli VISION_REF=v0.1.0 IMAGE_TAG=v0.1.0

# Custom external contexts
CPU_CONTAINER_CONTEXT=/opt/containers/vision \
GPU_CONTAINER_CONTEXT=/opt/containers/vision \
make image-build BIN=thumbnailer

# Override CUDA & Go versions via Makefile vars
CUDA_VERSION=12.4.1 GO_VERSION=1.23.3 make image-build GPU=1 BIN=vision-cli
```

Rationale:
- Faster iteration on container hardening (rootless tweaks, signing, SBOM) without touching application history.
- Ability to pin exact source refs for reproducible supply-chain attestations.
- Clean separation for future multi-repo architecture (`vision-core`, `vision-gpu`, etc.).

Security note: External Containerfiles clone source over HTTPS by default; for SSH access set `VISION_REPO` build arg in a wrapper script (avoid embedding secrets directly in build args).
