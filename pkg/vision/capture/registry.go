package capture

import (
	"strings"
	"sync"
)

// Factory creates a Source for a given src string and resolved Config.
// Implementations should be fast and avoid side effects until the Source is used.
type Factory func(src string, cfg Config) (Source, error)

var (
	regMu     sync.RWMutex
	factories = map[string]Factory{}
)

// Register associates a scheme (e.g. "file", "rtsp", "camera") with a Factory.
// It panics if the scheme is empty or already registered.
func Register(scheme string, f Factory) {
	if scheme == "" {
		panic("capture: empty scheme in Register")
	}
	regMu.Lock()
	defer regMu.Unlock()
	if _, exists := factories[scheme]; exists {
		panic("capture: duplicate register for scheme: " + scheme)
	}
	factories[scheme] = f
}

// Unregister removes a scheme; intended for tests / dynamic reconfiguration.
func Unregister(scheme string) {
	regMu.Lock()
	defer regMu.Unlock()
	delete(factories, scheme)
}

func lookupFactory(src string) Factory {
	if src == "" {
		return nil
	}
	// Basic scheme parsing: scheme:// or scheme: (first form preferred)
	scheme := ""
	if i := strings.Index(src, "://"); i > 0 {
		scheme = src[:i]
	} else if i := strings.IndexByte(src, ':'); i > 0 {
		scheme = src[:i]
	}
	if scheme == "" {
		return nil
	}
	regMu.RLock()
	defer regMu.RUnlock()
	return factories[scheme]
}
