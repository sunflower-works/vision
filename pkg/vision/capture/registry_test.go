package capture_test

import (
	"image"
	"image/color"
	"io"
	"testing"

	"github.com/sunflower-works/vision/pkg/vision/capture"
)

// simpleSource is a trivial Source for testing registry factories.
type simpleSource struct {
	left   int
	closed bool
	frame  image.Image
}

func newSimpleSource(n int) *simpleSource {
	img := image.NewRGBA(image.Rect(0, 0, 1, 1))
	img.Set(0, 0, color.RGBA{R: 1, G: 2, B: 3, A: 255})
	return &simpleSource{left: n, frame: img}
}

func (s *simpleSource) Next() (image.Image, error) {
	if s.closed {
		return nil, io.EOF
	}
	if s.left <= 0 {
		return nil, io.EOF
	}
	s.left--
	return s.frame, nil
}
func (s *simpleSource) Close() error { s.closed = true; return nil }

func TestRegistryFactoryInvocation(t *testing.T) {
	capture.Register("dummy", func(src string, cfg capture.Config) (capture.Source, error) {
		return newSimpleSource(3), nil
	})
	t.Cleanup(func() { capture.Unregister("dummy") })

	src, err := capture.Open("dummy://anything")
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	defer src.Close()
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
	}
	if n != 3 {
		t.Fatalf("expected 3 frames from dummy source, got %d", n)
	}
}

func TestRegistrySchemeColonForm(t *testing.T) {
	capture.Register("dummy2", func(src string, cfg capture.Config) (capture.Source, error) {
		return newSimpleSource(1), nil
	})
	t.Cleanup(func() { capture.Unregister("dummy2") })
	src, err := capture.Open("dummy2:raw")
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	defer src.Close()
	_, err = src.Next()
	if err != nil && err != io.EOF {
		t.Fatalf("unexpected err: %v", err)
	}
}

func TestWithMaxFrames(t *testing.T) {
	src, err := capture.Open("", capture.WithMaxFrames(7))
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	defer src.Close()
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
		if n > 20 {
			t.Fatalf("too many frames: %d", n)
		}
	}
	if n != 7 {
		t.Fatalf("expected MaxFrames=7, got %d", n)
	}
}
