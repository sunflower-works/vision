package pipeline_test

import (
	"testing"
	"github.com/sunflower-works/vision/pkg/vision/capture"
	"github.com/sunflower-works/vision/pkg/vision/pipeline"
)

func BenchmarkPipelineNoProcessors(b *testing.B) {
	for i := 0; i < b.N; i++ {
		src, err := capture.Open("", capture.WithMaxFrames(300))
		if err != nil { b.Fatalf("open: %v", err) }
		p := pipeline.New()
		b.StartTimer()
		_, err = p.Run(src)
		b.StopTimer()
		if err != nil { b.Fatalf("run: %v", err) }
	}
}

func BenchmarkPipelineWithProcessors(b *testing.B) {
	for i := 0; i < b.N; i++ {
		src, err := capture.Open("", capture.WithMaxFrames(300))
		if err != nil { b.Fatalf("open: %v", err) }
		p := pipeline.New().WithFPS().WithEdgeDetector()
		b.StartTimer()
		_, err = p.Run(src)
		b.StopTimer()
		if err != nil { b.Fatalf("run: %v", err) }
	}
}

