#!/usr/bin/env bash
set -euo pipefail
# Drift guard: ensure only the allowed set of workflow files exist.
# Default allowed: ci.yml, release.yml. Extend via EXTRA_ALLOWED (comma-separated) if needed.

WF_DIR=".github/workflows"
ALLOWED_BASE=(ci.yml release.yml)
if [[ -n "${EXTRA_ALLOWED:-}" ]]; then
  IFS=',' read -r -a EXTRA <<< "${EXTRA_ALLOWED}"
  ALLOWED_BASE+=("${EXTRA[@]}")
fi

if [[ ! -d "$WF_DIR" ]]; then
  echo "No workflows directory ($WF_DIR) present; nothing to check." >&2
  exit 0
fi

shopt -s nullglob
BAD=0
for f in "$WF_DIR"/*.yml "$WF_DIR"/*.yaml; do
  base=$(basename "$f")
  ok=1
  for a in "${ALLOWED_BASE[@]}"; do
    if [[ "$a" == "$base" ]]; then ok=0; break; fi
  done
  if [[ $ok -ne 0 ]]; then
    echo "Unexpected workflow file: $base" >&2
    BAD=1
  fi
done
shopt -u nullglob

if [[ $BAD -ne 0 ]]; then
  echo "Workflow drift detected." >&2
  exit 1
fi

echo "Workflow set OK (allowed: ${ALLOWED_BASE[*]})."

