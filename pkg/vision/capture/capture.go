package capture

import (
	"errors"
	"image"
	"image/color"
	"image/draw"
	"io"
	"time"
)

type Config struct {
	Width  int
	Height int
	FPS    int
}

type Option func(*Config)

func WithWidth(w int) Option {
	return func(c *Config) {
		if w > 0 {
			c.Width = w
		}
	}
}
func WithHeight(h int) Option {
	return func(c *Config) {
		if h > 0 {
			c.Height = h
		}
	}
}
func WithFPS(f int) Option {
	return func(c *Config) {
		if f > 0 {
			c.FPS = f
		}
	}
}

// Source provides frames to a pipeline.
type Source interface {
	Next() (image.Image, error) // io.EOF when stream is finished
	Close() error
}

type syntheticCam struct {
	cfg    Config
	frame  int
	max    int
	closed bool
	start  time.Time
}

// Open opens a camera or file path. For the skeleton, an empty src or "0"
// returns a synthetic source that produces a short animated sequence.
func Open(src string, opts ...Option) (Source, error) {
	cfg := Config{Width: 640, Height: 360, FPS: 30}
	for _, o := range opts {
		o(&cfg)
	}
	// Only synthetic source in the skeleton; treat any input as synthetic.
	return &syntheticCam{cfg: cfg, max: cfg.FPS * 5, start: time.Now()}, nil // ~5s
}

func (s *syntheticCam) Next() (image.Image, error) {
	if s.closed {
		return nil, errors.New("capture: closed")
	}
	if s.frame >= s.max {
		return nil, io.EOF
	}
	img := image.NewRGBA(image.Rect(0, 0, s.cfg.Width, s.cfg.Height))
	// background
	draw.Draw(img, img.Bounds(), &image.Uniform{color.RGBA{30, 30, 30, 255}}, image.Point{}, draw.Src)
	// animated bar
	barW := s.cfg.Width / 8
	x := (int(time.Since(s.start)/time.Millisecond) % (s.cfg.Width + barW)) - barW
	bar := image.Rect(x, 0, x+barW, s.cfg.Height)
	draw.Draw(img, bar, &image.Uniform{color.RGBA{200, 50, 50, 255}}, image.Point{}, draw.Src)
	s.frame++
	return img, nil
}

func (s *syntheticCam) Close() error { s.closed = true; return nil }
