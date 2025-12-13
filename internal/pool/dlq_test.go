package pool

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"

	"github.com/sparkiss/pos-cdc/internal/models"
	"github.com/sparkiss/pos-cdc/pkg/logger"
)

// TestMain sets up the logger for all tests in this package
func TestMain(m *testing.M) {
	// Initialize logger to avoid nil pointer
	logger.Init("error", "text")
	os.Exit(m.Run())
}

// TestDLQ_NewDLQ tests DLQ creation
func TestDLQ_NewDLQ(t *testing.T) {
	// Save current directory and change to temp
	origDir, _ := os.Getwd()
	tempDir := t.TempDir()
	os.Chdir(tempDir)
	defer os.Chdir(origDir)

	dlq := NewDLQ()
	defer dlq.Close()

	if dlq == nil {
		t.Fatal("NewDLQ() returned nil")
	}

	// Check that directory was created
	dlqDir := filepath.Join(tempDir, "var", "dlq")
	if _, err := os.Stat(dlqDir); os.IsNotExist(err) {
		t.Error("DLQ directory was not created")
	}

	// Initial count should be 0
	if count := dlq.Count(); count != 0 {
		t.Errorf("Count() = %d, want 0", count)
	}
}

// TestDLQ_Send tests adding events to DLQ
func TestDLQ_Send(t *testing.T) {
	// Save current directory and change to temp
	origDir, _ := os.Getwd()
	tempDir := t.TempDir()
	os.Chdir(tempDir)
	defer os.Chdir(origDir)

	dlq := NewDLQ()
	defer dlq.Close()

	event := &models.CDCEvent{
		Operation:   "c",
		Timestamp:   1735689600000,
		SourceDB:    "pos",
		SourceTable: "orders",
		Payload: map[string]any{
			"id":    1,
			"total": 99.99,
		},
	}

	testErr := errors.New("test error: database connection failed")
	dlq.Send(event, testErr)

	// Count should be 1
	if count := dlq.Count(); count != 1 {
		t.Errorf("Count() = %d, want 1", count)
	}

	// Verify entry was stored correctly
	if len(dlq.entries) != 1 {
		t.Fatalf("entries length = %d, want 1", len(dlq.entries))
	}

	entry := dlq.entries[0]
	if entry.Event != event {
		t.Error("entry.Event does not match sent event")
	}
	if entry.Error != testErr.Error() {
		t.Errorf("entry.Error = %q, want %q", entry.Error, testErr.Error())
	}
	if entry.Retries != 0 {
		t.Errorf("entry.Retries = %d, want 0", entry.Retries)
	}
	if entry.Timestamp.IsZero() {
		t.Error("entry.Timestamp should not be zero")
	}
}

// TestDLQ_Send_MultipleEvents tests adding multiple events
func TestDLQ_Send_MultipleEvents(t *testing.T) {
	origDir, _ := os.Getwd()
	tempDir := t.TempDir()
	os.Chdir(tempDir)
	defer os.Chdir(origDir)

	dlq := NewDLQ()
	defer dlq.Close()

	for i := 0; i < 5; i++ {
		event := &models.CDCEvent{
			Operation:   "c",
			SourceTable: "orders",
		}
		dlq.Send(event, errors.New("error"))
	}

	if count := dlq.Count(); count != 5 {
		t.Errorf("Count() = %d, want 5", count)
	}
}

// TestDLQ_Send_Concurrent tests thread safety
func TestDLQ_Send_Concurrent(t *testing.T) {
	origDir, _ := os.Getwd()
	tempDir := t.TempDir()
	os.Chdir(tempDir)
	defer os.Chdir(origDir)

	dlq := NewDLQ()
	defer dlq.Close()

	var wg sync.WaitGroup
	numGoroutines := 10
	eventsPerGoroutine := 10

	for i := 0; i < numGoroutines; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			for j := 0; j < eventsPerGoroutine; j++ {
				event := &models.CDCEvent{
					Operation:   "c",
					SourceTable: "orders",
				}
				dlq.Send(event, errors.New("concurrent error"))
			}
		}(i)
	}

	wg.Wait()

	expectedCount := numGoroutines * eventsPerGoroutine
	if count := dlq.Count(); count != expectedCount {
		t.Errorf("Count() = %d, want %d", count, expectedCount)
	}
}

// TestDLQ_FileWritten tests that events are persisted to file
func TestDLQ_FileWritten(t *testing.T) {
	origDir, _ := os.Getwd()
	tempDir := t.TempDir()
	os.Chdir(tempDir)
	defer os.Chdir(origDir)

	dlq := NewDLQ()

	event := &models.CDCEvent{
		Operation:   "u",
		SourceDB:    "pos",
		SourceTable: "products",
		Payload: map[string]any{
			"id":   42,
			"name": "Widget",
		},
	}

	dlq.Send(event, errors.New("file test error"))
	dlq.Close() // Ensure file is flushed

	// Read the file
	dlqPath := filepath.Join(tempDir, "var", "dlq", "dlq.jsonl")
	content, err := os.ReadFile(dlqPath)
	if err != nil {
		t.Fatalf("Failed to read DLQ file: %v", err)
	}

	if len(content) == 0 {
		t.Error("DLQ file is empty")
	}

	// Parse the JSON line
	var entry DLQEntry
	if err := json.Unmarshal(content[:len(content)-1], &entry); err != nil { // -1 to remove newline
		t.Fatalf("Failed to parse DLQ entry: %v", err)
	}

	if entry.Event.SourceTable != "products" {
		t.Errorf("entry.Event.SourceTable = %q, want %q", entry.Event.SourceTable, "products")
	}
	if entry.Error != "file test error" {
		t.Errorf("entry.Error = %q, want %q", entry.Error, "file test error")
	}
}

// TestDLQ_Close tests closing the DLQ
func TestDLQ_Close(t *testing.T) {
	origDir, _ := os.Getwd()
	tempDir := t.TempDir()
	os.Chdir(tempDir)
	defer os.Chdir(origDir)

	dlq := NewDLQ()

	// Close should not panic
	dlq.Close()

	// Calling Close again should not panic
	dlq.Close()
}

// TestDLQ_NoFile tests DLQ behavior when file cannot be created
func TestDLQ_NoFile(t *testing.T) {
	// Create a DLQ with nil file to simulate file creation failure
	dlq := &DLQ{
		entries: make([]DLQEntry, 0),
		file:    nil, // No file
	}

	event := &models.CDCEvent{
		Operation:   "c",
		SourceTable: "orders",
	}

	// Should not panic even without file
	dlq.Send(event, errors.New("no file test"))

	if count := dlq.Count(); count != 1 {
		t.Errorf("Count() = %d, want 1", count)
	}

	// Close should not panic with nil file
	dlq.Close()
}

// TestDLQEntry_JSONSerialization tests that entries serialize correctly
func TestDLQEntry_JSONSerialization(t *testing.T) {
	event := &models.CDCEvent{
		Operation:   "d",
		Timestamp:   1735689600000,
		SourceDB:    "pos",
		SourceTable: "users",
		Deleted:     "true",
	}

	entry := DLQEntry{
		Event:   event,
		Error:   "foreign key constraint failed",
		Retries: 3,
	}

	jsonBytes, err := json.Marshal(entry)
	if err != nil {
		t.Fatalf("Failed to marshal entry: %v", err)
	}

	jsonStr := string(jsonBytes)

	// Check that key fields are present
	if !strings.Contains(jsonStr, `"error":"foreign key constraint failed"`) {
		t.Error("JSON should contain error field")
	}
	if !strings.Contains(jsonStr, `"retries":3`) {
		t.Error("JSON should contain retries field")
	}
	if !strings.Contains(jsonStr, `"event"`) {
		t.Error("JSON should contain event field")
	}
}
