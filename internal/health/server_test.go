package health

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestNew(t *testing.T) {
	s := New(8081)
	if s == nil {
		t.Fatal("New() returned nil")
	}
	if s.httpServer == nil {
		t.Error("httpServer is nil")
	}
	if s.lastChecks == nil {
		t.Error("lastChecks map is nil")
	}
	if s.ready {
		t.Error("ready should be false by default")
	}
}

func TestServer_SetReady(t *testing.T) {
	s := New(8081)

	// Initially not ready
	if s.ready {
		t.Error("should not be ready initially")
	}

	// Set ready
	s.SetReady(true)
	if !s.ready {
		t.Error("should be ready after SetReady(true)")
	}

	// Set not ready
	s.SetReady(false)
	if s.ready {
		t.Error("should not be ready after SetReady(false)")
	}
}

func TestServer_UpdateCheck(t *testing.T) {
	s := New(8081)

	result := CheckResult{
		Healthy: true,
		Message: "MySQL connection OK",
	}

	s.UpdateCheck("mysql", result)

	// Verify the check was stored
	s.mu.RLock()
	storedResult, ok := s.lastChecks["mysql"]
	s.mu.RUnlock()

	if !ok {
		t.Fatal("check was not stored")
	}
	if !storedResult.Healthy {
		t.Error("stored result should be healthy")
	}
	if storedResult.Message != "MySQL connection OK" {
		t.Errorf("Message = %q, want %q", storedResult.Message, "MySQL connection OK")
	}
	if storedResult.Timestamp.IsZero() {
		t.Error("Timestamp should be set")
	}
}

func TestServer_HandleHealth(t *testing.T) {
	s := New(8081)

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()

	s.handleHealth(w, req)

	resp := w.Result()
	defer resp.Body.Close() //nolint:errcheck

	// Should always return 200 OK
	if resp.StatusCode != http.StatusOK {
		t.Errorf("StatusCode = %d, want %d", resp.StatusCode, http.StatusOK)
	}

	// Check content type
	contentType := resp.Header.Get("Content-Type")
	if contentType != "application/json" {
		t.Errorf("Content-Type = %q, want %q", contentType, "application/json")
	}

	// Parse response
	var response map[string]string
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	if response["status"] != "ok" {
		t.Errorf("status = %q, want %q", response["status"], "ok")
	}
}

func TestServer_HandleReady_NotReady(t *testing.T) {
	s := New(8081)
	s.SetReady(false)

	req := httptest.NewRequest(http.MethodGet, "/ready", nil)
	w := httptest.NewRecorder()

	s.handleReady(w, req)

	resp := w.Result()
	defer resp.Body.Close() //nolint:errcheck

	// Should return 503 Service Unavailable when not ready
	if resp.StatusCode != http.StatusServiceUnavailable {
		t.Errorf("StatusCode = %d, want %d", resp.StatusCode, http.StatusServiceUnavailable)
	}

	// Parse response
	var response map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	if response["ready"] != false {
		t.Errorf("ready = %v, want false", response["ready"])
	}
}

func TestServer_HandleReady_Ready(t *testing.T) {
	s := New(8081)
	s.SetReady(true)

	req := httptest.NewRequest(http.MethodGet, "/ready", nil)
	w := httptest.NewRecorder()

	s.handleReady(w, req)

	resp := w.Result()
	defer resp.Body.Close() //nolint:errcheck

	// Should return 200 OK when ready
	if resp.StatusCode != http.StatusOK {
		t.Errorf("StatusCode = %d, want %d", resp.StatusCode, http.StatusOK)
	}

	// Parse response
	var response map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	if response["ready"] != true {
		t.Errorf("ready = %v, want true", response["ready"])
	}
}

func TestServer_HandleReady_WithChecks(t *testing.T) {
	s := New(8081)
	s.SetReady(true)

	// Add some health checks
	s.UpdateCheck("mysql", CheckResult{
		Healthy: true,
		Message: "Connected",
	})
	s.UpdateCheck("kafka", CheckResult{
		Healthy: true,
		Message: "Consuming",
	})

	req := httptest.NewRequest(http.MethodGet, "/ready", nil)
	w := httptest.NewRecorder()

	s.handleReady(w, req)

	resp := w.Result()
	defer resp.Body.Close()

	// Parse response
	var response map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	// Check that checks are included
	checks, ok := response["checks"].(map[string]any)
	if !ok {
		t.Fatal("checks field is missing or not a map")
	}

	if len(checks) != 2 {
		t.Errorf("checks count = %d, want 2", len(checks))
	}

	// Verify mysql check
	mysqlCheck, ok := checks["mysql"].(map[string]any)
	if !ok {
		t.Fatal("mysql check is missing")
	}
	if mysqlCheck["healthy"] != true {
		t.Errorf("mysql.healthy = %v, want true", mysqlCheck["healthy"])
	}
}

func TestCheckResult_Fields(t *testing.T) {
	result := CheckResult{
		Healthy:   true,
		Message:   "All good",
		Timestamp: time.Now(),
	}

	if !result.Healthy {
		t.Error("Healthy should be true")
	}
	if result.Message != "All good" {
		t.Errorf("Message = %q, want %q", result.Message, "All good")
	}
	if result.Timestamp.IsZero() {
		t.Error("Timestamp should not be zero")
	}
}

func TestCheckResult_JSONSerialization(t *testing.T) {
	result := CheckResult{
		Healthy:   false,
		Message:   "Connection refused",
		Timestamp: time.Date(2025, 1, 1, 12, 0, 0, 0, time.UTC),
	}

	jsonBytes, err := json.Marshal(result)
	if err != nil {
		t.Fatalf("Failed to marshal: %v", err)
	}

	var parsed CheckResult
	if err := json.Unmarshal(jsonBytes, &parsed); err != nil {
		t.Fatalf("Failed to unmarshal: %v", err)
	}

	if parsed.Healthy != result.Healthy {
		t.Errorf("Healthy = %v, want %v", parsed.Healthy, result.Healthy)
	}
	if parsed.Message != result.Message {
		t.Errorf("Message = %q, want %q", parsed.Message, result.Message)
	}
}

func TestServer_Concurrency(t *testing.T) {
	s := New(8081)

	// Concurrent reads and writes
	done := make(chan bool)

	// Writer goroutine
	go func() {
		for i := 0; i < 100; i++ {
			s.SetReady(i%2 == 0)
			s.UpdateCheck("test", CheckResult{Healthy: true})
		}
		done <- true
	}()

	// Reader goroutine
	go func() {
		for i := 0; i < 100; i++ {
			req := httptest.NewRequest(http.MethodGet, "/ready", nil)
			w := httptest.NewRecorder()
			s.handleReady(w, req)
		}
		done <- true
	}()

	// Wait for both
	<-done
	<-done

	// If we got here without a race condition, the test passed
}

func TestServer_HTTPMux(t *testing.T) {
	s := New(8081)

	// Test that the mux routes are set up correctly
	testCases := []struct {
		path           string
		expectedStatus int
	}{
		{"/health", http.StatusOK},
		{"/ready", http.StatusServiceUnavailable}, // Not ready by default
	}

	for _, tc := range testCases {
		t.Run(tc.path, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, tc.path, nil)
			w := httptest.NewRecorder()

			s.httpServer.Handler.ServeHTTP(w, req)

			if w.Code != tc.expectedStatus {
				t.Errorf("GET %s: StatusCode = %d, want %d", tc.path, w.Code, tc.expectedStatus)
			}
		})
	}
}
