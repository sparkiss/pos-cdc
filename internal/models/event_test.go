package models

import (
	"testing"
	"time"
)

func TestCDCEvent_GetOperation(t *testing.T) {
	tests := []struct {
		name      string
		operation string
		want      Operation
	}{
		{"create operation", "c", OperationInsert},
		{"read/snapshot operation", "r", OperationInsert},
		{"update operation", "u", OperationUpdate},
		{"delete operation", "d", OperationDelete},
		{"unknown operation", "x", OperationUnknown},
		{"empty operation", "", OperationUnknown},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			event := &CDCEvent{Operation: tt.operation}
			if got := event.GetOperation(); got != tt.want {
				t.Errorf("GetOperation() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestCDCEvent_GetTime(t *testing.T) {
	tests := []struct {
		name      string
		timestamp int64
		wantYear  int
		wantMonth time.Month
		wantDay   int
	}{
		{
			name:      "epoch milliseconds for 2025-01-01 00:00:00 UTC",
			timestamp: 1735689600000,
			wantYear:  2025,
			wantMonth: time.January,
			wantDay:   1,
		},
		{
			name:      "epoch milliseconds for 2023-06-15 12:30:00 UTC",
			timestamp: 1686832200000,
			wantYear:  2023,
			wantMonth: time.June,
			wantDay:   15,
		},
		{
			name:      "zero timestamp",
			timestamp: 0,
			wantYear:  1970,
			wantMonth: time.January,
			wantDay:   1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			event := &CDCEvent{Timestamp: tt.timestamp}
			got := event.GetTime().UTC() // Convert to UTC for consistent test results

			if got.Year() != tt.wantYear {
				t.Errorf("GetTime().Year() = %v, want %v", got.Year(), tt.wantYear)
			}
			if got.Month() != tt.wantMonth {
				t.Errorf("GetTime().Month() = %v, want %v", got.Month(), tt.wantMonth)
			}
			if got.Day() != tt.wantDay {
				t.Errorf("GetTime().Day() = %v, want %v", got.Day(), tt.wantDay)
			}
		})
	}
}

func TestOperation_String(t *testing.T) {
	tests := []struct {
		name string
		op   Operation
		want string
	}{
		{"insert operation", OperationInsert, "INSERT"},
		{"update operation", OperationUpdate, "UPDATE"},
		{"delete operation", OperationDelete, "DELETE"},
		{"unknown operation", OperationUnknown, "UNKNOWN"},
		{"invalid operation value", Operation(99), "UNKNOWN"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.op.String(); got != tt.want {
				t.Errorf("Operation.String() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestCDCEvent_Fields(t *testing.T) {
	// Test that all fields are properly set and accessible
	event := &CDCEvent{
		Operation:   "c",
		Timestamp:   1735689600000,
		SourceDB:    "pos",
		SourceTable: "orders",
		Deleted:     "false",
		Topic:       "pos_mysql.pos.orders",
		Partition:   0,
		Payload: map[string]any{
			"id":    1,
			"total": 99.99,
		},
	}

	if event.SourceDB != "pos" {
		t.Errorf("SourceDB = %v, want %v", event.SourceDB, "pos")
	}
	if event.SourceTable != "orders" {
		t.Errorf("SourceTable = %v, want %v", event.SourceTable, "orders")
	}
	if event.Deleted != "false" {
		t.Errorf("Deleted = %v, want %v", event.Deleted, "false")
	}
	if event.Topic != "pos_mysql.pos.orders" {
		t.Errorf("Topic = %v, want %v", event.Topic, "pos_mysql.pos.orders")
	}
	if event.Partition != 0 {
		t.Errorf("Partition = %v, want %v", event.Partition, 0)
	}
	if len(event.Payload) != 2 {
		t.Errorf("Payload length = %v, want %v", len(event.Payload), 2)
	}
}
