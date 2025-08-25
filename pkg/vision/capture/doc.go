// Package capture provides frame Sources used by pipelines. It currently lives
// at module path github.com/sunflower-works/vision/pkg/vision/capture.
//
// Planned repository split:
//   - In a future extraction the stable, lightweight components (including this
//     interface and the synthetic source) will move to a new module:
//       github.com/sunflower-works/vision-core/pkg/vision/capture
//   - Heavier / optional backends (camera hardware, file/rtsp, ffmpeg, GPU) are
//     expected to reside in a sibling module (e.g. vision-capture-extra) and
//     register themselves via capture.Register.
//
// Migration guidance (PRE-RELEASE / EXPERIMENTAL):
//   - Until v1.0.0 the import path may change; a compatibility shim (re-export)
//     will be provided for at least one minor release cycle after the split.
//   - To prepare, depend only on the Source interface, Config, Option helpers,
//     and Open(). Avoid relying on unexported types or the syntheticCam struct.
//
// Stability: Experimental. Expect minor breaking adjustments while < v0.2.
// SemVer: After the split, vision-core will adopt stricter SemVer guarantees.
//
// NOTE: If you vendor today, be ready to update import paths once the split
// lands. Track REPO_SPLIT_PLAN.md for progress.
package capture

