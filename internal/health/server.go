package health

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.uber.org/zap"

	"github.com/sparkiss/pos-cdc/pkg/logger"
)

// Server provides health and metrics endpoints
type Server struct {
	httpServer *http.Server
	mu         sync.RWMutex
	ready      bool
	lastChecks map[string]CheckResult
}

// CheckResult holds health check result
type CheckResult struct {
	Healthy   bool      `json:"healthy"`
	Message   string    `json:"message,omitempty"`
	Timestamp time.Time `json:"timestamp"`
}

// New creates a health server
func New(port int) *Server {
	s := &Server{
		lastChecks: make(map[string]CheckResult),
	}

	mux := http.NewServeMux()

	// Health endpoint - for liveness probe
	mux.HandleFunc("/health", s.handleHealth)

	// Ready endpoint - for readiness probe
	mux.HandleFunc("/ready", s.handleReady)

	// Metrics endpoint - for Prometheus
	mux.Handle("/metrics", promhttp.Handler())

	s.httpServer = &http.Server{
		Addr:    fmt.Sprintf(":%d", port),
		Handler: mux,
	}

	return s
}

// Start begins serving
func (s *Server) Start() error {
	logger.Log.Info("Health server starting",
		zap.String("addr", s.httpServer.Addr))
	return s.httpServer.ListenAndServe()
}

// Stop gracefully shuts down
func (s *Server) Stop() error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	return s.httpServer.Shutdown(ctx)
}

// SetReady marks the service as ready
func (s *Server) SetReady(ready bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.ready = ready
}

// UpdateCheck updates a health check result
func (s *Server) UpdateCheck(name string, result CheckResult) {
	s.mu.Lock()
	defer s.mu.Unlock()
	result.Timestamp = time.Now()
	s.lastChecks[name] = result
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	// Liveness: just return OK if process is running
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func (s *Server) handleReady(w http.ResponseWriter, r *http.Request) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	response := map[string]any{
		"ready":  s.ready,
		"checks": s.lastChecks,
	}

	w.Header().Set("Content-Type", "application/json")

	if !s.ready {
		w.WriteHeader(http.StatusServiceUnavailable)
	}

	_ = json.NewEncoder(w).Encode(response)
}
