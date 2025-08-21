package main

import "testing"

func TestRunSynthetic(t *testing.T) {
	args := []string{"-src", "", "-width", "64", "-height", "64", "-fps", "5"}
	if err := Run(args); err != nil {
		t.Fatalf("Run returned error: %v", err)
	}
}
