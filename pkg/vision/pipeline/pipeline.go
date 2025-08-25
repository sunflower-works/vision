package pipeline

import (
	"image"
	"io"
	"time"

	"github.com/sunflower-works/vision/pkg/vision/capture"
)

type Processor interface {
	Process(image.Image) (image.Image, error)
}

type ProcessorFunc func(image.Image) (image.Image, error)

func (f ProcessorFunc) Process(img image.Image) (image.Image, error) { return f(img) }

// ProcessorFactory creates a Processor given a config map (reserved for future use).
type ProcessorFactory func() Processor

// Registry for processors (edge, fps overlay, etc.)
var procRegistry = map[string]ProcessorFactory{}

// RegisterProcessor registers a named processor factory (panics on duplicate).
func RegisterProcessor(name string, f ProcessorFactory) {
	if name == "" {
		panic("pipeline: empty processor name")
	}
	if _, exists := procRegistry[name]; exists {
		panic("pipeline: duplicate processor: " + name)
	}
	procRegistry[name] = f
}

// GetProcessor retrieves a registered processor factory (nil if absent).
func GetProcessor(name string) ProcessorFactory { return procRegistry[name] }

// Built-in processors
func init() {
	RegisterProcessor("edge", func() Processor {
		return ProcessorFunc(func(img image.Image) (image.Image, error) {
			return img, nil
		})
	})
	RegisterProcessor("fps", func() Processor {
		return ProcessorFunc(func(img image.Image) (image.Image, error) {
			return img, nil
		})
	})
}

type Pipeline struct {
	processors []Processor
}

func New() *Pipeline { return &Pipeline{} }

// WithFPS adds (placeholder) fps overlay processor.
func (p *Pipeline) WithFPS() *Pipeline {
	if f := GetProcessor("fps"); f != nil {
		p.processors = append(p.processors, f())
	}
	return p
}

// WithEdgeDetector adds a placeholder edge detector.
func (p *Pipeline) WithEdgeDetector() *Pipeline {
	if f := GetProcessor("edge"); f != nil {
		p.processors = append(p.processors, f())
	}
	return p
}

// Run pulls frames, applies processors sequentially, counts frames.
func (p *Pipeline) Run(src capture.Source) (int, error) {
	defer func() { _ = src.Close() }()
	var frames int
	start := time.Now() // retained for potential fps logic
	_ = start
	for {
		img, err := src.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return frames, err
		}
		for _, pr := range p.processors {
			img, err = pr.Process(img)
			if err != nil {
				return frames, err
			}
		}
		_ = img // ignore transformed image for now
		frames++
	}
	return frames, nil
}
