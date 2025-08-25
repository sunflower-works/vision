#!/usr/bin/env bash
set -euo pipefail
# Update all central-ci reusable workflow references to the version in .github/central-ci.version.
# Usage: scripts/update-central-ci-ref.sh [--check]
#   --check  : fail if any change would be made (no in-place edits)
# Environment:
#   DRY_RUN=true  : same as --check
#   VERBOSE=1     : print files as they are processed
VERSION_FILE=".github/central-ci.version"
WF_DIR=".github/workflows"
CHECK_MODE=false
if [[ "${1:-}" == "--check" ]]; then CHECK_MODE=true; fi
if [[ "${DRY_RUN:-false}" == "true" ]]; then CHECK_MODE=true; fi
if [[ ! -f "$VERSION_FILE" ]]; then
  echo "Version file $VERSION_FILE not found" >&2
  exit 1
fi
VERSION=$(tr -d ' \n' < "$VERSION_FILE")
if [[ -z "$VERSION" ]]; then
  echo "Empty version in $VERSION_FILE" >&2
  exit 1
fi
shopt -s nullglob
CHANGED=0
for f in "$WF_DIR"/*.yml "$WF_DIR"/*.yaml; do
  [[ -e "$f" ]] || continue
  BEFORE_HASH=$(md5sum "$f" | awk '{print $1}')
  # Use a temp file to avoid in-place sed portability issues on macOS (if used).
  TMP="$f.tmp.$$"
  # Replace any @v* token after central-ci workflow path with @${VERSION}
  # Pattern matches: sunflower-works/central-ci/.github/workflows/<name>.yml@<version>
  sed -E "s@(sunflower-works/central-ci/.github/workflows/[A-Za-z0-9_.-]+)@v[0-9][A-Za-z0-9_.-]*@\\1@${VERSION}@g" "$f" > "$TMP"
  AFTER_HASH=$(md5sum "$TMP" | awk '{print $1}')
  if [[ "$BEFORE_HASH" != "$AFTER_HASH" ]]; then
    if $CHECK_MODE; then
      echo "Would update: $f" >&2
      CHANGED=1
    else
      mv "$TMP" "$f"
      rm -f "$f".bak 2>/dev/null || true
      echo "Updated: $f" | { [[ -n "${VERBOSE:-}" ]] && cat || true; }
    fi
  else
    rm -f "$TMP"
  fi
  if [[ -n "${VERBOSE:-}" ]]; then
    grep -E "uses: .*sunflower-works/central-ci" "$f" || true
  fi
done
shopt -u nullglob
if $CHECK_MODE; then
  if [[ $CHANGED -ne 0 ]]; then
    echo "central-ci references NOT up-to-date with $VERSION_FILE ($VERSION)." >&2
    exit 2
  fi
  echo "central-ci references already at $VERSION." >&2
fi

