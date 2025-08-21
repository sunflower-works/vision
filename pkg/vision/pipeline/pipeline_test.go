package pipeline_test

import (
	"testing"

	"github.com/sunflower-works/vision/pkg/vision/capture"
	"github.com/sunflower-works/vision/pkg/vision/pipeline"
)

func TestPipelineRunCountsFrames(t *testing.T) {
	src, err := capture.Open(capture.WithFPS(10))
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	defer src.Close()

	p := pipeline.New().WithFPS().WithEdgeDetector()
	n, err := p.Run(src)
	if err != nil {
		t.Fatalf("run: %v", err)
	}
	if n <= 0 {
		t.Fatalf("expected >0 frames, got %d", n)
	}
}
