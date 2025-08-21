# sunflower-vision

A small, composable computer vision toolkit that complements the sunflower SDK.

- Public API under `pkg/vision` (capture, pipeline, model, draw)
- Demo binaries in `cmd/`
- Private implementation under `internal/`

Quick start:

```bash
cd vision
go run ./cmd/vision-cli
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

See `.github/workflows/ci.yml` for a minimal Go vet + test matrix (Linux/macOS).

## License

MIT

