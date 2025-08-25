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
	Width     int
	Height    int
	FPS       int
	MaxFrames int // optional override; if >0 limits total frames (default ~5s)
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

// WithMaxFrames caps the number of frames produced (synthetic sources only for now).
func WithMaxFrames(n int) Option {
	return func(c *Config) {
		if n > 0 {
			c.MaxFrames = n
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

// Open opens a camera or file path. Delegates to a registered factory if one
// matches the scheme/prefix; otherwise falls back to the synthetic source for now.
func Open(src string, opts ...Option) (Source, error) {
	cfg := Config{Width: 640, Height: 360, FPS: 30}
	for _, o := range opts {
		o(&cfg)
	}
	if f := lookupFactory(src); f != nil { // will be provided by registry.go
		return f(src, cfg)
	}
	max := cfg.FPS * 5
	if cfg.MaxFrames > 0 {
		max = cfg.MaxFrames
	}
	return &syntheticCam{cfg: cfg, max: max, start: time.Now()}, nil // ~5s
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
	draw.Draw(img, img.Bounds(), &image.Uniform{C: color.RGBA{R: 30, G: 30, B: 30, A: 255}}, image.Point{}, draw.Src)
	// animated bar
	barW := s.cfg.Width / 8
	x := (int(time.Since(s.start)/time.Millisecond) % (s.cfg.Width + barW)) - barW
	bar := image.Rect(x, 0, x+barW, s.cfg.Height)
	draw.Draw(img, bar, &image.Uniform{C: color.RGBA{R: 200, G: 50, B: 50, A: 255}}, image.Point{}, draw.Src)
	s.frame++
	return img, nil
}

func (s *syntheticCam) Close() error { s.closed = true; return nil }
