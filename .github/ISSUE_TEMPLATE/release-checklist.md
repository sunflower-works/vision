---
name: Release Checklist
about: Prepare and execute a versioned release
title: "Release: vX.Y.Z"
labels: [release]
assignees: []
---

## Pre-flight
- [ ] Decide version (semver) -> `vX.Y.Z`
- [ ] Update version in `pkg/vision/version/version.go`
- [ ] Update `CHANGELOG.md` (Added / Changed / Fixed / Deprecated / Removed / Security)
- [ ] Run: `make release-check`
- [ ] Ensure all central-ci workflows green on `main` (CI, Lint, Security, CodeQL, YAML Lint)
- [ ] Confirm no local workflow drift (all delegators only)

## Tag & Publish
- [ ] Trigger GitHub Release workflow (Actions > Release > Run workflow) with tag `vX.Y.Z`
- [ ] Verify tag pushed and release notes generated
- [ ] (If needed) Update major alias tag (e.g. force-update `v0` or `v1`)

## Post-Release
- [ ] Announce internally (link to release notes)
- [ ] Open new `Unreleased` section atop `CHANGELOG.md`
- [ ] Create follow-up issues for deferred items / tech debt

## Validation Artifacts
Paste key command outputs:
```
make version
head -n 20 CHANGELOG.md
```

## Notes
(Any anomalies, manual steps, or rollback considerations.)

