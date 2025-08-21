# Contributing to sunflower-vision

Thanks for your interest in contributing! This guide covers the basics to get you productive quickly.

## Getting started

- Go version: 1.24+
- Clone and install tools:
  - golangci-lint (optional locally; CI runs it): https://golangci-lint.run/
  - govulncheck (optional locally; CI runs it): `go install golang.org/x/vuln/cmd/govulncheck@latest`

## Development workflow

- Tidy, build, vet:
  - `go mod tidy`
  - `go vet ./...`
- Test (race + coverage):
  - `go test -race -count=1 -covermode=atomic -coverprofile=coverage.out ./...`
  - `go tool cover -func=coverage.out | tail -n1`
- Lint:
  - `golangci-lint run` (uses `.golangci.yml`)

## Protobuf codegen

Generated files under `pkg/vision/eye/*.pb.go` are produced from the `.proto` sources and shouldn’t be edited manually.

Prereqs:
- Install `protoc` (3.21+)
- Install the Go plugin:
  - `go install google.golang.org/protobuf/cmd/protoc-gen-go@latest`

Regenerate:
```bash
# From repo root
go generate ./pkg/vision/eye
# Then tidy and test
go mod tidy
go test ./...
```

## Commit and PR guidelines

- Small, focused PRs are easier to review.
- Include tests for new behavior.
- Keep public API changes in `pkg/vision/**` minimal and documented.
- Run tidy/vet/test locally before opening a PR.
- The CI pipeline enforces:
  - go mod tidy consistency
  - vet, race tests with coverage threshold
  - golangci-lint
  - govulncheck

## Project structure

- `pkg/vision/` – public, stable API (capture, pipeline, model, draw)
- `cmd/` – sample binaries and demos
- `internal/` – implementation details (subject to change)
- `examples/` – small, copy/pasteable snippets (<100 LOC)

## Reporting bugs and requesting features

- Open a GitHub issue with a minimal reproduction or a clear problem statement.
- For features, describe the use case and expected API shape.

## Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).
