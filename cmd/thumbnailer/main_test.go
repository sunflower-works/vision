package main

import (
	"image/jpeg"
	"os"
	"path/filepath"
	"testing"
)

func TestRunWritesJPEG(t *testing.T) {
	dir := t.TempDir()
	out := filepath.Join(dir, "thumb.jpg")
	if err := Run([]string{"-src", "", "-out", out}); err != nil {
		t.Fatalf("Run error: %v", err)
	}
	fh, err := os.Open(out)
	if err != nil {
		t.Fatalf("open output: %v", err)
	}
	t.Cleanup(func() { _ = fh.Close() })
	if _, err := jpeg.DecodeConfig(fh); err != nil {
		t.Fatalf("decode output: %v", err)
	}
}
