package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/sunflower-works/vision/pkg/vision/capture"
	"github.com/sunflower-works/vision/pkg/vision/pipeline"
)

// Run executes the CLI with provided args. Returns error instead of exiting.
func Run(args []string) error {
	fs := flag.NewFlagSet("vision-cli", flag.ContinueOnError)
	// Suppress default output in tests; main() will handle stderr
	fs.SetOutput(os.Stderr)
	src := fs.String("src", "", "camera ID or file path (empty = synthetic)")
	w := fs.Int("width", 640, "frame width")
	h := fs.Int("height", 360, "frame height")
	fps := fs.Int("fps", 30, "frames per second")
	if err := fs.Parse(args); err != nil {
		return err
	}

	cam, err := capture.Open(*src, capture.WithWidth(*w), capture.WithHeight(*h), capture.WithFPS(*fps))
	if err != nil {
		return err
	}
	defer cam.Close()

	pipe := pipeline.New().WithFPS().WithEdgeDetector()

	start := time.Now()
	frames, err := pipe.Run(cam)
	if err != nil {
		return err
	}
	elapsed := time.Since(start).Seconds()
	if elapsed == 0 {
		elapsed = 1
	}
	fmt.Printf("processed %d frames in %.2fs (%.1f fps)\n", frames, elapsed, float64(frames)/elapsed)
	return nil
}

func main() {
	if err := Run(os.Args[1:]); err != nil {
		log.Fatal(err)
	}
}
