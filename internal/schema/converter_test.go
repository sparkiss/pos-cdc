// internal/schema/converter_test.go

//go:build integration

package schema

import (
	"testing"
	"time"
)

func TestConvertValue_DateTime(t *testing.T) {
	col := &ColumnInfo{Name: "created_at", DataType: "datetime"}

	tests := []struct {
		name  string
		input any
		check func(any) bool
	}{
		{
			name:  "epoch milliseconds",
			input: float64(1761898503000),
			check: func(v any) bool {
				t, ok := v.(time.Time)
				return ok && t.Year() == 2025
			},
		},
		{
			name:  "epoch seconds",
			input: int64(1735689600),
			check: func(v any) bool {
				t, ok := v.(time.Time)
				return ok && t.Year() == 2025
			},
		},
		{
			name:  "ISO string",
			input: "2025-01-01T12:00:00Z",
			check: func(v any) bool {
				t, ok := v.(time.Time)
				return ok && t.Year() == 2025
			},
		},
		{
			name:  "nil value",
			input: nil,
			check: func(v any) bool {
				return v == nil
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := ConvertValue(col, tt.input)
			if !tt.check(result) {
				t.Errorf("ConvertValue(%v) = %v, check failed", tt.input, result)
			}
		})
	}
}

func TestConvertValue_BigInt(t *testing.T) {
	col := &ColumnInfo{Name: "id", DataType: "bigint"}

	// Large number should NOT be converted to time
	input := float64(9999999999999) // Larger than 1e12
	result := ConvertValue(col, input)

	// Should pass through unchanged (not converted to time)
	if result != input {
		t.Errorf("bigint value was incorrectly converted: %v -> %v", input, result)
	}
}

func TestConvertValue_Date(t *testing.T) {
	col := &ColumnInfo{Name: "birth_date", DataType: "date"}

	// Days since epoch (e.g., 19000 = ~2022-01-01)
	input := float64(19358) // 2023-01-01
	result := ConvertValue(col, input)

	str, ok := result.(string)
	if !ok {
		t.Fatalf("expected string, got %T", result)
	}

	if str != "2023-01-01" {
		t.Errorf("expected 2023-01-01, got %s", str)
	}
}

func TestSchemaCache_RealDatabase(t *testing.T) {
	dsn := "root:password@tcp(localhost:3307)/pos?parseTime=true"
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	cache := schema.New(db, "pos")

	// Test getting full schema
	tableSchema, err := cache.GetTableSchema("account")
	if err != nil {
		t.Fatalf("failed to get schema: %v", err)
	}

	t.Logf("Table: %s", tableSchema.Name)
	t.Logf("Primary Keys: %v", tableSchema.PrimaryKeys)
	t.Logf("Columns:")
	for name, col := range tableSchema.Columns {
		t.Logf("  %s: %s (nullable=%v, pk=%v)", name, col.DataType, col.IsNullable, col.IsPrimary)
	}

	// Verify caching (second call should use cache)
	tableSchema2, _ := cache.GetTableSchema("account")
	if tableSchema != tableSchema2 {
		t.Error("expected same pointer from cache")
	}
}
