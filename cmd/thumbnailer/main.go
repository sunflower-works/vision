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
	out := fs.String("out", "thumb.jpg", "output JPEG path")
	if err := fs.Parse(args); err != nil {
		return err
	}

	src, err := capture.Open(capture.WithWidth(320), capture.WithHeight(180), capture.WithFPS(1))
	if err != nil {
		return err
	}
	defer func(src capture.Source) {
		err := src.Close()
		if err != nil {
			log.Printf("error closing source: %v", err)
		} else {
			log.Printf("source closed successfully")
		}
	}(src)

	img, err := src.Next()
	if err != nil {
		return err
	}
	fh, err := os.Create(*out)
	if err != nil {
		return err
	}
	defer func(fh *os.File) {
		err := fh.Close()
		if err != nil {
			log.Printf("error closing file: %v", err)
		} else {
			log.Printf("file closed successfully")
		}
	}(fh)
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
