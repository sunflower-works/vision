package capture_test

import (
	"io"
	"testing"

	"github.com/sunflower-works/vision/pkg/vision/capture"
)

func TestSyntheticOpenAndIterate(t *testing.T) {
	src, err := capture.Open("")
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	t.Cleanup(func() { _ = src.Close() })

	var n int
	for {
		_, err := src.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			t.Fatalf("next: %v", err)
		}
		n++
		if n > 10000 { // guard against infinite loop in case of regression
			t.Fatalf("too many frames without EOF: %d", n)
		}
	}
	if n == 0 {
		t.Fatalf("expected some frames, got 0")
	}
}
