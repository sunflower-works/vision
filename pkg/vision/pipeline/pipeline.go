package pipeline

import (
	"io"
	"time"

	"github.com/sunflower-works/vision/pkg/vision/capture"
)

type Pipeline struct {
	withFPS  bool
	withEdge bool
}

func New() *Pipeline { return &Pipeline{} }

func (p *Pipeline) WithFPS() *Pipeline          { p.withFPS = true; return p }
func (p *Pipeline) WithEdgeDetector() *Pipeline { p.withEdge = true; return p }

// Run pulls frames from the source until EOF and returns the total count.
// This skeleton doesn't perform actual image processing yet; it simulates
// work and optional FPS tracking.
func (p *Pipeline) Run(src capture.Source) (int, error) {
	defer func() { _ = src.Close() }()
	var frames int
	start := time.Now()
	for {
		_, err := src.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return frames, err
		}
		frames++
		// Simulate light processing cost for edge detector
		if p.withEdge {
			_ = frames % 2 // no-op branch to keep the compiler honest
		}
		if p.withFPS && frames%100 == 0 {
			_ = time.Since(start) // placeholder for future FPS overlay
		}
	}
	return frames, nil
}
