package schema

import (
	"testing"
	"time"

	"github.com/sparkiss/pos-cdc/internal/config"
)

func TestNewConverter(t *testing.T) {
	tests := []struct {
		name       string
		sourceLoc  *time.Location
		targetLoc  *time.Location
		wantSource string
		wantTarget string
	}{
		{
			name:       "both nil defaults to UTC",
			sourceLoc:  nil,
			targetLoc:  nil,
			wantSource: "UTC",
			wantTarget: "UTC",
		},
		{
			name:       "custom locations",
			sourceLoc:  time.FixedZone("MST", -7*3600),
			targetLoc:  time.FixedZone("EST", -5*3600),
			wantSource: "MST",
			wantTarget: "EST",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := NewConverter(tt.sourceLoc, tt.targetLoc, config.TargetMySQL)
			if c.sourceLocation.String() != tt.wantSource {
				t.Errorf("sourceLocation = %v, want %v", c.sourceLocation, tt.wantSource)
			}
			if c.targetLocation.String() != tt.wantTarget {
				t.Errorf("targetLocation = %v, want %v", c.targetLocation, tt.wantTarget)
			}
		})
	}
}

func TestConverter_ConvertValue_Nil(t *testing.T) {
	c := NewConverter(nil, nil, config.TargetMySQL)
	col := &ColumnInfo{Name: "test", DataType: "datetime"}

	result := c.ConvertValue(col, nil)
	if result != nil {
		t.Errorf("ConvertValue(nil) = %v, want nil", result)
	}
}

func TestConverter_ConvertValue_DateTime(t *testing.T) {
	// The converter logic:
	// 1. time.UnixMilli(epoch) returns time in LOCAL timezone
	// 2. Takes wall-clock values and interprets as source timezone
	// 3. Converts to target timezone
	//
	// For predictable tests, we use string inputs which bypass epoch conversion

	c := NewConverter(time.UTC, time.UTC, config.TargetMySQL)
	col := &ColumnInfo{Name: "created_at", DataType: "datetime"}

	tests := []struct {
		name      string
		input     any
		wantCheck func(any) bool
	}{
		{
			name:  "ISO8601 string with Z",
			input: "2025-01-01T12:30:45Z",
			wantCheck: func(v any) bool {
				s, ok := v.(string)
				return ok && s == "2025-01-01 12:30:45"
			},
		},
		{
			name:  "ISO8601 string without timezone",
			input: "2025-01-01T12:30:45",
			wantCheck: func(v any) bool {
				s, ok := v.(string)
				return ok && s == "2025-01-01 12:30:45"
			},
		},
		{
			name:  "MySQL format passthrough",
			input: "2025-01-01 12:30:45",
			wantCheck: func(v any) bool {
				s, ok := v.(string)
				return ok && s == "2025-01-01 12:30:45"
			},
		},
		{
			name:  "RFC3339 format",
			input: "2025-01-01T12:30:45+00:00",
			wantCheck: func(v any) bool {
				s, ok := v.(string)
				return ok && s == "2025-01-01 12:30:45"
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := c.ConvertValue(col, tt.input)
			if !tt.wantCheck(result) {
				t.Errorf("ConvertValue(%v) = %v, check failed", tt.input, result)
			}
		})
	}
}

func TestConverter_EpochToMySQLDateTime(t *testing.T) {
	// The epochToMySQLDateTime function uses time.UnixMilli which returns
	// local time, then interprets wall-clock as source TZ and converts to target TZ.
	//
	// For this test, we verify the conversion logic works correctly
	// by checking that same source/target TZ preserves the local wall-clock.

	// Get system local timezone
	localTZ := time.Local

	// Create converter with local timezone for both source and target
	c := NewConverter(localTZ, localTZ, config.TargetMySQL)

	// Use a known epoch and calculate expected local time
	epoch := int64(1735689600000) // 2025-01-01 00:00:00 UTC
	expectedTime := time.UnixMilli(epoch).Format("2006-01-02 15:04:05")

	result := c.epochToDateTime(epoch)
	if result != expectedTime {
		t.Errorf("epochToMySQLDateTime() = %v, want %v (local time)", result, expectedTime)
	}
}

func TestConverter_ConvertValue_DateTime_Timezone(t *testing.T) {
	// Test timezone conversion with string input (bypasses local TZ issues)
	// Source is Mountain Time (UTC-7), Target is UTC

	sourceLoc := time.FixedZone("MST", -7*3600)
	c := NewConverter(sourceLoc, time.UTC, config.TargetMySQL)
	col := &ColumnInfo{Name: "created_at", DataType: "datetime"}

	// ISO string without TZ is interpreted as source timezone
	// "12:00:00 MST" converted to UTC = "19:00:00 UTC"
	input := "2025-01-01T12:00:00"
	result := c.ConvertValue(col, input)

	s, ok := result.(string)
	if !ok {
		t.Fatalf("expected string, got %T", result)
	}

	// 12:00 MST (UTC-7) = 19:00 UTC
	if s != "2025-01-01 19:00:00" {
		t.Errorf("ConvertValue() = %v, want 2025-01-01 19:00:00", s)
	}
}

func TestConverter_ConvertValue_DateTime_SameTimezone(t *testing.T) {
	// When source and target are the same, wall-clock time is preserved
	toronto, _ := time.LoadLocation("America/Toronto")
	c := NewConverter(toronto, toronto, config.TargetMySQL)
	col := &ColumnInfo{Name: "created_at", DataType: "datetime"}

	// ISO string without TZ - interpreted as source, converted to same target
	input := "2025-01-01T12:30:45"
	result := c.ConvertValue(col, input)

	s, ok := result.(string)
	if !ok {
		t.Fatalf("expected string, got %T", result)
	}

	// Same timezone in and out, wall-clock preserved
	if s != "2025-01-01 12:30:45" {
		t.Errorf("ConvertValue() = %v, want 2025-01-01 12:30:45", s)
	}
}

func TestConverter_ConvertValue_Timestamp(t *testing.T) {
	c := NewConverter(time.UTC, time.UTC, config.TargetMySQL)
	col := &ColumnInfo{Name: "updated_at", DataType: "timestamp"}

	// Use string input to test timestamp type handling (same as datetime)
	input := "2025-01-01T00:00:00Z"
	result := c.ConvertValue(col, input)

	s, ok := result.(string)
	if !ok {
		t.Fatalf("expected string, got %T", result)
	}
	if s != "2025-01-01 00:00:00" {
		t.Errorf("ConvertValue() = %v, want 2025-01-01 00:00:00", s)
	}
}

func TestConverter_ConvertValue_Date(t *testing.T) {
	c := NewConverter(time.UTC, time.UTC, config.TargetMySQL)
	col := &ColumnInfo{Name: "birth_date", DataType: "date"}

	tests := []struct {
		name  string
		input any
		want  string
	}{
		{
			name:  "days since epoch float64",
			input: float64(19358), // 2023-01-01
			want:  "2023-01-01",
		},
		{
			name:  "days since epoch int64",
			input: int64(19358),
			want:  "2023-01-01",
		},
		{
			name:  "days since epoch int",
			input: int(19358),
			want:  "2023-01-01",
		},
		{
			name:  "string passthrough",
			input: "2023-06-15",
			want:  "2023-06-15",
		},
		{
			name:  "epoch day 0",
			input: int64(0),
			want:  "1970-01-01",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := c.ConvertValue(col, tt.input)
			s, ok := result.(string)
			if !ok {
				t.Fatalf("expected string, got %T", result)
			}
			if s != tt.want {
				t.Errorf("ConvertValue(%v) = %v, want %v", tt.input, s, tt.want)
			}
		})
	}
}

func TestConverter_ConvertValue_Time(t *testing.T) {
	c := NewConverter(nil, nil, config.TargetMySQL)
	col := &ColumnInfo{Name: "start_time", DataType: "time"}

	tests := []struct {
		name  string
		input any
		want  string
	}{
		{
			name:  "milliseconds float64",
			input: float64(45296000), // 12:34:56
			want:  "12:34:56",
		},
		{
			name:  "milliseconds int64",
			input: int64(45296000),
			want:  "12:34:56",
		},
		{
			name:  "zero time",
			input: int64(0),
			want:  "00:00:00",
		},
		{
			name:  "string passthrough",
			input: "15:30:00",
			want:  "15:30:00",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := c.ConvertValue(col, tt.input)
			s, ok := result.(string)
			if !ok {
				t.Fatalf("expected string, got %T: %v", result, result)
			}
			if s != tt.want {
				t.Errorf("ConvertValue(%v) = %v, want %v", tt.input, s, tt.want)
			}
		})
	}
}

func TestMillisToTimeString(t *testing.T) {
	tests := []struct {
		name string
		ms   int64
		want string
	}{
		{"zero", 0, "00:00:00"},
		{"one second", 1000, "00:00:01"},
		{"one minute", 60000, "00:01:00"},
		{"one hour", 3600000, "01:00:00"},
		{"12:34:56", 45296000, "12:34:56"},
		{"23:59:59", 86399000, "23:59:59"},
		{"negative becomes zero", -1000, "00:00:00"},
		{"large value", 100 * 3600000, "100:00:00"}, // Over 24 hours
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := millisToTimeString(tt.ms); got != tt.want {
				t.Errorf("millisToTimeString(%v) = %v, want %v", tt.ms, got, tt.want)
			}
		})
	}
}

func TestConverter_ConvertValue_Bool(t *testing.T) {
	c := NewConverter(nil, nil, config.TargetMySQL)

	tests := []struct {
		name     string
		dataType string
		input    any
		want     bool
	}{
		{"bit true from bool", "bit", true, true},
		{"bit false from bool", "bit", false, false},
		{"bool true from float64 1", "bool", float64(1), true},
		{"bool false from float64 0", "bool", float64(0), false},
		{"boolean true from int64 1", "boolean", int64(1), true},
		{"boolean false from int64 0", "boolean", int64(0), false},
		{"bit true from int 1", "bit", int(1), true},
		{"bit false from int 0", "bit", int(0), false},
		{"bool true from string 1", "bool", "1", true},
		{"bool true from string true", "bool", "true", true},
		{"bool true from string TRUE", "bool", "TRUE", true},
		{"bool false from string 0", "bool", "0", false},
		{"bool false from string false", "bool", "false", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			col := &ColumnInfo{Name: "flag", DataType: tt.dataType}
			result := c.ConvertValue(col, tt.input)
			got, ok := result.(bool)
			if !ok {
				t.Fatalf("expected bool, got %T: %v", result, result)
			}
			if got != tt.want {
				t.Errorf("ConvertValue(%v) = %v, want %v", tt.input, got, tt.want)
			}
		})
	}
}

func TestConverter_ConvertValue_Passthrough(t *testing.T) {
	c := NewConverter(nil, nil, config.TargetMySQL)

	tests := []struct {
		dataType string
		input    any
	}{
		{"int", int64(42)},
		{"bigint", int64(9999999999999)},
		{"smallint", int(100)},
		{"tinyint", int(1)},
		{"mediumint", int(50000)},
		{"decimal", "123.45"},
		{"numeric", float64(123.45)},
		{"float", float64(3.14)},
		{"double", float64(3.14159265359)},
		{"varchar", "hello world"},
		{"char", "A"},
		{"text", "long text content"},
		{"longtext", "very long text"},
		{"mediumtext", "medium text"},
		{"tinytext", "tiny"},
		{"json", `{"key": "value"}`},
	}

	for _, tt := range tests {
		t.Run(tt.dataType, func(t *testing.T) {
			col := &ColumnInfo{Name: "test_col", DataType: tt.dataType}
			result := c.ConvertValue(col, tt.input)
			if result != tt.input {
				t.Errorf("ConvertValue(%v) = %v, want passthrough", tt.input, result)
			}
		})
	}
}

func TestConverter_ConvertValue_Blob(t *testing.T) {
	c := NewConverter(nil, nil, config.TargetMySQL)
	col := &ColumnInfo{Name: "data", DataType: "blob"}

	input := []byte("binary data")
	result := c.ConvertValue(col, input)

	// Blob should be passed through
	resultBytes, ok := result.([]byte)
	if !ok {
		t.Fatalf("expected []byte, got %T", result)
	}
	if string(resultBytes) != string(input) {
		t.Errorf("ConvertValue() = %v, want %v", resultBytes, input)
	}
}

func TestConverter_ConvertValue_UnknownType(t *testing.T) {
	c := NewConverter(nil, nil, config.TargetMySQL)
	col := &ColumnInfo{Name: "custom", DataType: "custom_unknown_type"}

	input := "some value"
	result := c.ConvertValue(col, input)

	if result != input {
		t.Errorf("ConvertValue() = %v, want %v (passthrough for unknown type)", result, input)
	}
}

func TestConverter_PostgresTypes(t *testing.T) {
	// Test PostgreSQL-specific type names that differ from MySQL
	c := NewConverter(time.UTC, time.UTC, config.TargetPostgres)

	tests := []struct {
		name     string
		dataType string
		input    any
		check    func(any) bool
	}{
		// Temporal types
		{
			name:     "timestamp with time zone from epoch ms",
			dataType: "timestamp with time zone",
			input:    float64(1735689600000), // 2025-01-01 00:00:00 UTC
			check: func(v any) bool {
				_, ok := v.(time.Time)
				return ok
			},
		},
		{
			name:     "timestamp without time zone from epoch ms",
			dataType: "timestamp without time zone",
			input:    float64(1735689600000),
			check: func(v any) bool {
				_, ok := v.(time.Time)
				return ok
			},
		},
		{
			name:     "time with time zone passthrough",
			dataType: "time with time zone",
			input:    int64(45296000), // 12:34:56 in ms
			check: func(v any) bool {
				s, ok := v.(string)
				return ok && s == "12:34:56"
			},
		},
		// Numeric types
		{
			name:     "integer passthrough",
			dataType: "integer",
			input:    int64(42),
			check: func(v any) bool {
				return v == int64(42)
			},
		},
		{
			name:     "double precision passthrough",
			dataType: "double precision",
			input:    float64(3.14159),
			check: func(v any) bool {
				return v == float64(3.14159)
			},
		},
		{
			name:     "real passthrough",
			dataType: "real",
			input:    float64(3.14),
			check: func(v any) bool {
				return v == float64(3.14)
			},
		},
		// String types
		{
			name:     "character varying passthrough",
			dataType: "character varying",
			input:    "hello",
			check: func(v any) bool {
				return v == "hello"
			},
		},
		{
			name:     "character passthrough",
			dataType: "character",
			input:    "A",
			check: func(v any) bool {
				return v == "A"
			},
		},
		// Binary
		{
			name:     "bytea passthrough",
			dataType: "bytea",
			input:    []byte("binary data"),
			check: func(v any) bool {
				b, ok := v.([]byte)
				return ok && string(b) == "binary data"
			},
		},
		// JSON
		{
			name:     "jsonb passthrough",
			dataType: "jsonb",
			input:    `{"key": "value"}`,
			check: func(v any) bool {
				return v == `{"key": "value"}`
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			col := &ColumnInfo{Name: "test_col", DataType: tt.dataType}
			result := c.ConvertValue(col, tt.input)
			if !tt.check(result) {
				t.Errorf("ConvertValue(%v) for %s = %v (%T), check failed", tt.input, tt.dataType, result, result)
			}
		})
	}
}

func TestConverter_ParseISO8601DateTime(t *testing.T) {
	c := NewConverter(time.UTC, time.UTC, config.TargetMySQL)

	tests := []struct {
		name  string
		input string
		want  string
	}{
		{
			name:  "RFC3339 with timezone",
			input: "2025-01-01T12:30:45+00:00",
			want:  "2025-01-01 12:30:45",
		},
		{
			name:  "UTC with Z suffix",
			input: "2025-01-01T12:30:45Z",
			want:  "2025-01-01 12:30:45",
		},
		{
			name:  "no timezone info",
			input: "2025-01-01T12:30:45",
			want:  "2025-01-01 12:30:45",
		},
		{
			name:  "already MySQL format",
			input: "2025-01-01 12:30:45",
			want:  "2025-01-01 12:30:45",
		},
		{
			name:  "invalid format passes through",
			input: "not a date",
			want:  "not a date",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := c.parseISO8601DateTime(tt.input)
			if got != tt.want {
				t.Errorf("parseISO8601DateTime(%v) = %v, want %v", tt.input, got, tt.want)
			}
		})
	}
}
