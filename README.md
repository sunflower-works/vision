# sunflower-vision

[![CI](https://github.com/sunflower-works/vision/actions/workflows/ci.yml/badge.svg)](https://github.com/sunflower-works/vision/actions/workflows/ci.yml)
[![Lint](https://github.com/sunflower-works/vision/actions/workflows/lint.yml/badge.svg)](https://github.com/sunflower-works/vision/actions/workflows/lint.yml)
[![Coverage](https://img.shields.io/badge/coverage-auto--generated-blue)](https://github.com/sunflower-works/vision/actions/workflows/ci.yml)

A small, composable computer vision toolkit that complements the sunflower SDK.

- Public API under `pkg/vision` (capture, pipeline, model, draw)
- Demo binaries in `cmd/`
- Private implementation under `internal/`

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

- cmd/vision-cli: CLI demo runner
- pkg/vision/capture: sources (camera/file/rtsp) — synthetic stub here
- pkg/vision/pipeline: simple processing graph — stubbed
- internal/: private cgo wrappers and utilities
- examples/: tiny samples (<100 LOC)
- assets/, testdata/: small fixtures and golden files

## CI
All validation (tests, coverage, lint, CodeQL, govuln, YAML lint) runs in a single aggregated workflow: `.github/workflows/ci.yml`. Release tagging uses `release.yml` (manual dispatch).

See `.github/workflows/ci.yml` for test matrix and coverage; lint in `.github/workflows/lint.yml`.

## Contributing

Contributions are welcome! Please read the guidelines in [CONTRIBUTING.md](CONTRIBUTING.md). By participating, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## License

MIT