package pool

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sync"
	"time"

	"go.uber.org/zap"

	"github.com/sparkiss/pos-cdc/internal/models"
	"github.com/sparkiss/pos-cdc/pkg/logger"
)

// DLQEntry represents a failed event
type DLQEntry struct {
	Event     *models.CDCEvent `json:"event"`
	Error     string           `json:"error"`
	Timestamp time.Time        `json:"timestamp"`
	Retries   int              `json:"retries"`
}

// DLQ manages failed events
type DLQ struct {
	entries []DLQEntry
	mu      sync.Mutex
	file    *os.File
}

// NewDLQ creates a new DLQ
func NewDLQ() *DLQ {
	// DLQ file path in var/dlq/ directory
	dlqPath := filepath.Join("var", "dlq", "dlq.jsonl")

	// Create directory if it doesn't exist
	if err := os.MkdirAll(filepath.Dir(dlqPath), 0755); err != nil {
		logger.Log.Warn("Failed to create DLQ directory",
			zap.String("path", filepath.Dir(dlqPath)),
			zap.Error(err))
	}

	// Open DLQ file for appending
	file, err := os.OpenFile(dlqPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		logger.Log.Warn("Failed to open DLQ file, using memory only",
			zap.String("path", dlqPath),
			zap.Error(err))
	}

	return &DLQ{
		entries: make([]DLQEntry, 0),
		file:    file,
	}
}

// Send adds a failed event to the DLQ
func (d *DLQ) Send(event *models.CDCEvent, err error) {
	entry := DLQEntry{
		Event:     event,
		Error:     err.Error(),
		Timestamp: time.Now(),
		Retries:   0,
	}

	d.mu.Lock()
	defer d.mu.Unlock()

	d.entries = append(d.entries, entry)

	// Persist to file
	if d.file != nil {
		if jsonBytes, err := json.Marshal(entry); err == nil {
			_, _ = d.file.Write(jsonBytes)
			_, _ = d.file.WriteString("\n")
		}
	}

	logger.Log.Error("Event sent to DLQ",
		zap.String("table", event.SourceTable),
		zap.String("op", event.Operation),
		zap.Error(err))
}

// Count returns the number of entries in the DLQ
func (d *DLQ) Count() int {
	d.mu.Lock()
	defer d.mu.Unlock()
	return len(d.entries)
}

// Close closes the DLQ file
func (d *DLQ) Close() {
	if d.file != nil {
		_ = d.file.Close()
	}
}
