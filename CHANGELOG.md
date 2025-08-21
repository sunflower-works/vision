# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## v0.1.0 - 2025-08-21
- Initial skeleton module
  - Public API stubs: pkg/vision/capture, pkg/vision/pipeline, pkg/vision/draw, pkg/vision/model
  - Protobufs: pkg/vision/eye/frame.pb.go and h264.pb.go
  - Demo binaries: cmd/vision-cli, cmd/thumbnailer (now testable)
  - CI: test (race+coverage, tidy guard), lint (golangci-lint), security (govulncheck)
  - Docs: README with badges, CONTRIBUTING, CODE_OF_CONDUCT

