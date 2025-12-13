package config

import (
	"os"
	"testing"
	"time"
)

func TestGetEnv(t *testing.T) {
	tests := []struct {
		name         string
		key          string
		defaultValue string
		envValue     string
		setEnv       bool
		want         string
	}{
		{
			name:         "returns default when env not set",
			key:          "TEST_GET_ENV_UNSET",
			defaultValue: "default_value",
			setEnv:       false,
			want:         "default_value",
		},
		{
			name:         "returns env value when set",
			key:          "TEST_GET_ENV_SET",
			defaultValue: "default_value",
			envValue:     "actual_value",
			setEnv:       true,
			want:         "actual_value",
		},
		{
			name:         "returns default when env is empty string",
			key:          "TEST_GET_ENV_EMPTY",
			defaultValue: "default_value",
			envValue:     "",
			setEnv:       true,
			want:         "default_value",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Clean up before and after test
			os.Unsetenv(tt.key)        //nolint:errcheck
			defer os.Unsetenv(tt.key)  //nolint:errcheck

			if tt.setEnv {
				os.Setenv(tt.key, tt.envValue) //nolint:errcheck
			}

			if got := getEnv(tt.key, tt.defaultValue); got != tt.want {
				t.Errorf("getEnv() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestGetEnvInt(t *testing.T) {
	tests := []struct {
		name         string
		key          string
		defaultValue int
		envValue     string
		setEnv       bool
		want         int
	}{
		{
			name:         "returns default when env not set",
			key:          "TEST_GET_ENV_INT_UNSET",
			defaultValue: 42,
			setEnv:       false,
			want:         42,
		},
		{
			name:         "returns parsed int when valid",
			key:          "TEST_GET_ENV_INT_VALID",
			defaultValue: 42,
			envValue:     "100",
			setEnv:       true,
			want:         100,
		},
		{
			name:         "returns default when invalid int",
			key:          "TEST_GET_ENV_INT_INVALID",
			defaultValue: 42,
			envValue:     "not_a_number",
			setEnv:       true,
			want:         42,
		},
		{
			name:         "returns default when empty",
			key:          "TEST_GET_ENV_INT_EMPTY",
			defaultValue: 42,
			envValue:     "",
			setEnv:       true,
			want:         42,
		},
		{
			name:         "handles negative numbers",
			key:          "TEST_GET_ENV_INT_NEGATIVE",
			defaultValue: 0,
			envValue:     "-5",
			setEnv:       true,
			want:         -5,
		},
		{
			name:         "handles zero",
			key:          "TEST_GET_ENV_INT_ZERO",
			defaultValue: 42,
			envValue:     "0",
			setEnv:       true,
			want:         0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			os.Unsetenv(tt.key)        //nolint:errcheck
			defer os.Unsetenv(tt.key)  //nolint:errcheck

			if tt.setEnv {
				os.Setenv(tt.key, tt.envValue) //nolint:errcheck
			}

			if got := getEnvInt(tt.key, tt.defaultValue); got != tt.want {
				t.Errorf("getEnvInt() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestParseList(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  []string
	}{
		{
			name:  "empty string returns nil",
			input: "",
			want:  nil,
		},
		{
			name:  "single item",
			input: "orders",
			want:  []string{"orders"},
		},
		{
			name:  "multiple items",
			input: "orders,users,products",
			want:  []string{"orders", "users", "products"},
		},
		{
			name:  "items with whitespace",
			input: " orders , users , products ",
			want:  []string{"orders", "users", "products"},
		},
		{
			name:  "empty items are filtered out",
			input: "orders,,users,",
			want:  []string{"orders", "users"},
		},
		{
			name:  "only whitespace items are filtered",
			input: "orders,   ,users",
			want:  []string{"orders", "users"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := parseList(tt.input)

			if tt.want == nil {
				if got != nil {
					t.Errorf("parseList() = %v, want nil", got)
				}
				return
			}

			if len(got) != len(tt.want) {
				t.Errorf("parseList() length = %v, want %v", len(got), len(tt.want))
				return
			}

			for i, v := range got {
				if v != tt.want[i] {
					t.Errorf("parseList()[%d] = %v, want %v", i, v, tt.want[i])
				}
			}
		})
	}
}

func TestConfig_IsTableExcluded(t *testing.T) {
	tests := []struct {
		name           string
		excludedTables []string
		tableName      string
		want           bool
	}{
		{
			name:           "empty exclusion list",
			excludedTables: nil,
			tableName:      "orders",
			want:           false,
		},
		{
			name:           "table is excluded",
			excludedTables: []string{"logs", "sessions", "temp_data"},
			tableName:      "logs",
			want:           true,
		},
		{
			name:           "table is not excluded",
			excludedTables: []string{"logs", "sessions"},
			tableName:      "orders",
			want:           false,
		},
		{
			name:           "case sensitive match",
			excludedTables: []string{"Logs"},
			tableName:      "logs",
			want:           false,
		},
		{
			name:           "exact match required",
			excludedTables: []string{"log"},
			tableName:      "logs",
			want:           false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cfg := &Config{ExcludedTables: tt.excludedTables}
			if got := cfg.IsTableExcluded(tt.tableName); got != tt.want {
				t.Errorf("IsTableExcluded() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestConfig_TargetDSN(t *testing.T) {
	cfg := &Config{
		TargetDB: DBConfig{
			Host:     "localhost",
			Port:     3307,
			User:     "root",
			Password: "secret123",
			Database: "pos_replica",
		},
	}

	want := "root:secret123@tcp(localhost:3307)/pos_replica?parseTime=true&loc=UTC"
	if got := cfg.TargetDSN(); got != want {
		t.Errorf("TargetDSN() = %v, want %v", got, want)
	}
}

func TestConfig_TargetDSN_SpecialCharacters(t *testing.T) {
	cfg := &Config{
		TargetDB: DBConfig{
			Host:     "db.example.com",
			Port:     3306,
			User:     "app_user",
			Password: "p@ss:word/special",
			Database: "mydb",
		},
	}

	// Note: Special characters in password should be URL-encoded in production
	// This test documents current behavior
	got := cfg.TargetDSN()
	if got == "" {
		t.Error("TargetDSN() returned empty string")
	}
}

func TestLoad_ValidationErrors(t *testing.T) {
	// Save original env vars
	originalPassword := os.Getenv("TARGET_DB_PASSWORD")
	defer os.Setenv("TARGET_DB_PASSWORD", originalPassword) //nolint:errcheck

	// Test missing required field
	os.Unsetenv("TARGET_DB_PASSWORD")
	_, err := Load()
	if err == nil {
		t.Error("Load() should return error when TARGET_DB_PASSWORD is missing")
	}
}

func TestLoad_InvalidTimezone(t *testing.T) {
	// Save and set required env vars
	originalPassword := os.Getenv("TARGET_DB_PASSWORD")
	originalSourceTZ := os.Getenv("SOURCE_DB_TIMEZONE")

	defer func() {
		os.Setenv("TARGET_DB_PASSWORD", originalPassword)
		if originalSourceTZ != "" {
			os.Setenv("SOURCE_DB_TIMEZONE", originalSourceTZ)
		} else {
			os.Unsetenv("SOURCE_DB_TIMEZONE")
		}
	}()

	os.Setenv("TARGET_DB_PASSWORD", "test_password")
	os.Setenv("SOURCE_DB_TIMEZONE", "Invalid/Timezone")

	_, err := Load()
	if err == nil {
		t.Error("Load() should return error for invalid SOURCE_DB_TIMEZONE")
	}
}

func TestLoad_ValidConfig(t *testing.T) {
	// Save original env vars
	envVars := []string{
		"TARGET_DB_PASSWORD",
		"TARGET_DB_HOST",
		"TARGET_DB_PORT",
		"KAFKA_BROKERS",
		"WORKER_COUNT",
		"EXCLUDED_TABLES",
		"SOURCE_DB_TIMEZONE",
		"TARGET_DB_TIMEZONE",
	}

	originalValues := make(map[string]string)
	for _, key := range envVars {
		originalValues[key] = os.Getenv(key)
	}

	defer func() {
		for key, value := range originalValues {
			if value != "" {
				os.Setenv(key, value)
			} else {
				os.Unsetenv(key)
			}
		}
	}()

	// Set test values
	os.Setenv("TARGET_DB_PASSWORD", "test_password")
	os.Setenv("TARGET_DB_HOST", "testhost")
	os.Setenv("TARGET_DB_PORT", "3308")
	os.Setenv("KAFKA_BROKERS", "broker1:9092,broker2:9092")
	os.Setenv("WORKER_COUNT", "8")
	os.Setenv("EXCLUDED_TABLES", "logs,sessions")
	os.Setenv("SOURCE_DB_TIMEZONE", "America/Denver")
	os.Setenv("TARGET_DB_TIMEZONE", "UTC")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	// Verify values
	if cfg.TargetDB.Host != "testhost" {
		t.Errorf("TargetDB.Host = %v, want testhost", cfg.TargetDB.Host)
	}
	if cfg.TargetDB.Port != 3308 {
		t.Errorf("TargetDB.Port = %v, want 3308", cfg.TargetDB.Port)
	}
	if len(cfg.KafkaBrokers) != 2 {
		t.Errorf("KafkaBrokers length = %v, want 2", len(cfg.KafkaBrokers))
	}
	if cfg.WorkerCount != 8 {
		t.Errorf("WorkerCount = %v, want 8", cfg.WorkerCount)
	}
	if len(cfg.ExcludedTables) != 2 {
		t.Errorf("ExcludedTables length = %v, want 2", len(cfg.ExcludedTables))
	}
	if cfg.SourceLocation == nil {
		t.Error("SourceLocation is nil")
	}
	if cfg.TargetLocation == nil {
		t.Error("TargetLocation is nil")
	}

	// Verify timezone was parsed correctly
	denverLoc, _ := time.LoadLocation("America/Denver")
	if cfg.SourceLocation.String() != denverLoc.String() {
		t.Errorf("SourceLocation = %v, want %v", cfg.SourceLocation, denverLoc)
	}
}
