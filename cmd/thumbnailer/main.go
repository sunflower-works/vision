package main

import (
	"flag"
	"image/jpeg"
	"log"
	"os"

	"github.com/sunflower-works/vision/pkg/vision/capture"
)

// Run executes the thumbnailer CLI with provided args.
func Run(args []string) error {
	fs := flag.NewFlagSet("thumbnailer", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	in := fs.String("src", "", "input (camera id or file, empty = synthetic)")
	out := fs.String("out", "thumb.jpg", "output JPEG path")
	if err := fs.Parse(args); err != nil {
		return err
	}

	src, err := capture.Open(*in, capture.WithWidth(320), capture.WithHeight(180), capture.WithFPS(1))
	if err != nil {
		return err
	}
	defer src.Close()

	img, err := src.Next()
	if err != nil {
		return err
	}
	fh, err := os.Create(*out)
	if err != nil {
		return err
	}
	defer fh.Close()
	if err := jpeg.Encode(fh, img, &jpeg.Options{Quality: 80}); err != nil {
		return err
	}
	log.Printf("wrote %s", *out)
	return nil
}

func main() {
	if err := Run(os.Args[1:]); err != nil {
		log.Fatal(err)
	}
}
