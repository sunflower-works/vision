# Vision Repository Split Plan

Goal: Decompose the current `vision` module into smaller, purpose-focused repositories to improve API clarity, release cadence control, and optional dependency isolation (e.g. GPU / heavy capture backends).

## Target Repositories (Proposed)

1. vision-core
   - Packages: `capture` interfaces + synthetic source, `pipeline` interfaces/basic impl, `draw`, `model` (pure, dependency-light), `version`.
   - Guarantees stable API (semantic versioning focus here first).

2. vision-capture-extra
   - Non-synthetic / heavier capture backends (camera devices, file/ffmpeg/rtsp, platform specific code, cgo wrappers).
   - Build tags for optional drivers.

3. vision-pipeline-ops
   - Additional processors (edge detectors, object detection stubs, transforms, overlays) that depend on external libs (OpenCV, CUDA, etc.).

4. vision-cli (or vision-apps)
   - Command-line binaries (`vision-cli`, `thumbnailer`, future demos) depending only on published APIs of `vision-core` (+ optionally extra repos).

5. vision-containers
   - Containerfile(s), build automation (Makefile fragments), SBOM/VEX tooling.
   - Optional consolidation point for multi-repo build orchestration (GitHub Actions reusable workflows referencing each repo).

6. vision-gpu (deferred until GPU code lands)
   - CUDA / GPU accelerated compute backends, kernels, scheduler integrations.

## Rationale
- Reduce churn surface for downstream users: `vision-core` becomes very stable.
- Allow separate version bumps and independent release notes.
- Enable lighter dependency graph for simple CPU-only users.
- Clear contribution routing: capture vs pipeline vs apps.

## High-Level Dependency Direction
```
vision-cli ---> vision-core
               |        \
               v         v
        vision-capture-extra   vision-pipeline-ops
                     \           /
                      --> vision-gpu (optional future)
```
Containers tooling may reference any subset but must not introduce code-level imports back into core.

## Minimal Extraction Order
1. Introduce interfaces & registries (DONE for capture; NEXT: pipeline Processor registry) while still monolithic.
2. Freeze public API and add package doc comments clarifying future module path.
3. Copy code to new repo (git filter-repo) preserving history for each subtree.
4. Adjust module paths in copies (`module github.com/sunflower-works/vision-core`).
5. Add replace directives in legacy monorepo (temporary) or move consumers directly.
6. Deprecate overlapping paths in original repo (final stage) and optionally convert to meta-repo with go.work for local dev convenience.

## Tooling: History-Preserving Split
Pre-req: install git-filter-repo.

Script (also provided in `scripts/split-out.sh`):
```bash
#!/usr/bin/env bash
set -euo pipefail
BASE_REPO=${BASE_REPO:-"$(pwd)"}
SPLIT_DIR=${SPLIT_DIR:-"../vision-split"}
mkdir -p "$SPLIT_DIR"

# map: new_repo_name:paths (space separated if multiple)
REPOS=( \
  "vision-core:pkg/vision/capture pkg/vision/pipeline pkg/vision/draw pkg/vision/model pkg/vision/version" \
  "vision-cli:cmd/vision-cli cmd/thumbnailer" \
)

echo "==> Preparing temporary clone"
TMP_CLONE=$(mktemp -d)
cp -R "$BASE_REPO/." "$TMP_CLONE"
(cd "$TMP_CLONE" && git gc --aggressive --prune=now || true)

for entry in "${REPOS[@]}"; do
  name=${entry%%:*}
  paths=${entry#*:}
  echo "==> Splitting $name ($paths)"
  WORK_DIR="$SPLIT_DIR/$name"
  rm -rf "$WORK_DIR" && mkdir -p "$WORK_DIR"
  (cd "$TMP_CLONE" && git filter-repo --force --path-rename pkg/vision/=pkg/vision/ --path "$(echo $paths | sed 's/ / --path /g')")
  # Move filtered repo
  cp -R "$TMP_CLONE/." "$WORK_DIR" || true
  # Reset tmp clone for next iteration
  rm -rf "$TMP_CLONE" && TMP_CLONE=$(mktemp -d) && cp -R "$BASE_REPO/." "$TMP_CLONE"
  echo "Initialized $WORK_DIR"
  # Initialize go.mod (defer editing of imports)
  cat > "$WORK_DIR/go.mod" <<EOF
module github.com/sunflower-works/$name

go 1.24
EOF
  cat > "$WORK_DIR/README.md" <<EOF
# $name (extracted from vision)

History-preserved extraction. Adjust import paths:
- Before: github.com/sunflower-works/vision/pkg/vision/...
- After:  github.com/sunflower-works/$name/pkg/vision/...
EOF
  (cd "$WORK_DIR" && git init && git add . && git commit -m "Initial extraction from vision")
  echo "Next: create remote repo and push: git remote add origin git@github.com:sunflower-works/$name.git && git push -u origin main"
done

echo "All splits staged in $SPLIT_DIR"
```
*Note:* The simplistic loop resets history each time; for multiple independent path filters you may instead clone once per repo to truly preserve isolated history per subtree. Adjust as needed.

## Post-Split Steps
- Update downstream imports (search/replace vision/pkg/vision -> vision-core/pkg/vision etc.).
- Add tags/releases in each repo matching latest version (align CHANGELOG scope accordingly).
- Introduce CI per new repo referencing central workflows (already present in `central-ci`).
- Establish dependency constraints (e.g., vision-cli go.mod depends on vision-core via semver tag).

## Future Enhancements
- Add `go.work` at a higher-level dev meta-repo for simultaneous local development across modules.
- Provide an aggregator module (optional) that re-exports select stable APIs for simplified onboarding.
- Use provenance attestations (cosign) across all split images.

## Immediate Next Tasks (Phase 1 Follow-up)
- Add pipeline Processor interface + registry (mirrors capture) BEFORE splitting pipeline code.
- Introduce lightweight benchmarks (capture read loop, pipeline run) to measure regression during refactor.

## Risks / Mitigations
| Risk | Mitigation |
|------|------------|
| Breaking import paths prematurely | Delay removal in original repo; add deprecation notes first |
| Diverging versions across sub-repos | Define release policy: core first, then apps update |
| History fragmentation | Use git filter-repo carefully; test resulting blame/log before pushing |
| Hidden transitive dependencies | Run `go mod tidy && go list -deps` in each new repo before publish |

## Status
- Capture registry implemented.
- Ready to add pipeline registry before extraction.

---
Questions to answer before executing split:
1. Do we want an umbrella meta-repo (monorepo orchestrator) or fully independent repos only? (Default: independent + optional go.work meta.)
2. Do we freeze version at v0.x across all until structure stable? (Recommended.)
3. Do we maintain a compatibility shim inside original `vision` repo for at least one minor cycle? (Recommended.)

