// Package pipeline defines a simple frame processing pipeline and an
// extensible registry for image Processors. Current module path:
//
//	github.com/sunflower-works/vision/pkg/vision/pipeline
//
// Planned split (see REPO_SPLIT_PLAN.md):
//   - Core abstractions (Pipeline, Processor interface, registration helpers)
//     expected to move to: github.com/sunflower-works/vision-core/pkg/vision/pipeline
//   - Additional / heavy processors (e.g. GPU accelerated, ML inference) will
//     live in separate modules (e.g. vision-pipeline-ops, vision-gpu) and
//     register themselves at init-time.
//
// Migration strategy:
//   - While project is < v1.0.0, import path may change. A temporary shim in
//     the original repo (re-exporting symbols) will ease migration.
//   - Downstream code should avoid depending on unexported details and prefer
//     Processor interface + registration functions for extensibility.
//
// Stability: Experimental (< v0.2). Public API may evolve; core concepts (Source
// feeding Pipeline of Processors) are intended to stabilize before v0.5.
package pipeline
