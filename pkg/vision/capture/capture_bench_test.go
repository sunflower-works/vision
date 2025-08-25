package capture_test

import (
	"testing"
	"github.com/sunflower-works/vision/pkg/vision/capture"
)

func BenchmarkSyntheticCapture(b *testing.B) {
	// Each iteration reads N frames; reset timer to exclude setup.
	const frames = 300
	for i := 0; i < b.N; i++ {
		src, err := capture.Open("", capture.WithMaxFrames(frames))
		if err != nil { b.Fatalf("open: %v", err) }
		b.StartTimer()
		count := 0
		for {
			_, err := src.Next()
			if err != nil { break }
			count++
		}
		b.StopTimer()
		_ = src.Close()
		if count != frames { b.Fatalf("expected %d frames got %d", frames, count) }
	}
}

