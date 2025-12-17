package config

import (
	"fmt"
	"os"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

// TargetType represents the target database type
type TargetType string

const (
	TargetMySQL    TargetType = "mysql"
	TargetPostgres TargetType = "postgres"
)

// Config holds all application configuration
type Config struct {
	// Target database selection
	TargetType TargetType

	// MySQL target database (used when TargetType == "mysql")
	TargetDB DBConfig

	// PostgreSQL target database (used when TargetType == "postgres")
	TargetPG PGConfig

	// Kafka/Redpanda
	KafkaBrokers         []string
	KafkaGroupID         string
	KafkaAutoOffsetReset string

	// Application behavior
	LogLevel       string
	LogFormat      string // "json" or "text"
	WorkerCount    int
	BatchSize      int
	MaxRetries     int
	RetryBackoffMS int

	// Tables to exclude from replication
	ExcludedTables []string

	// Monitoring
	MetricsPort int
	HealthPort  int

	// Timezone settings
	// Source: how datetimes are stored in source DB (Debezium interprets as UTC)
	// Target: how datetimes should be stored in target DB
	SourceTimezone string
	SourceLocation *time.Location
	TargetTimezone string
	TargetLocation *time.Location
}

// DBConfig holds MySQL database connection settings
type DBConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	Database string
}

// PGConfig holds PostgreSQL database connection settings
type PGConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	Database string
	SSLMode  string // disable, require, verify-ca, verify-full
}

// Load reads configuration from environment variables
// Looks for .env file first, then falls back to actual env vars
func Load() (*Config, error) {
	// Try to load .env file (ignore error if not found)
	// 📚 Search: "godotenv golang" for docs
	_ = godotenv.Load()

	cfg := &Config{
		TargetType: TargetType(getEnv("TARGET_TYPE", "postgres")),
		TargetDB: DBConfig{
			Host:     getEnv("TARGET_DB_HOST", "localhost"),
			Port:     getEnvInt("TARGET_DB_PORT", 3307),
			User:     getEnv("TARGET_DB_USER", "root"),
			Password: getEnv("TARGET_DB_PASSWORD", ""),
			Database: getEnv("TARGET_DB_NAME", "pos"),
		},
		TargetPG: PGConfig{
			Host:     getEnv("TARGET_PG_HOST", "localhost"),
			Port:     getEnvInt("TARGET_PG_PORT", 5432),
			User:     getEnv("TARGET_PG_USER", "cdc_writer"),
			Password: getEnv("TARGET_PG_PASSWORD", ""),
			Database: getEnv("TARGET_PG_DATABASE", "pos_replica"),
			SSLMode:  getEnv("TARGET_PG_SSLMODE", "disable"),
		},
		KafkaBrokers:         strings.Split(getEnv("KAFKA_BROKERS", "localhost:9092"), ","),
		KafkaGroupID:         getEnv("KAFKA_GROUP_ID", "cdc-consumer-group"),
		KafkaAutoOffsetReset: getEnv("KAFKA_AUTO_OFFSET_RESET", "earliest"),
		LogLevel:             getEnv("LOG_LEVEL", "info"),
		LogFormat:            getEnv("LOG_FORMAT", "text"),
		WorkerCount:          getEnvInt("WORKER_COUNT", 4),
		BatchSize:            getEnvInt("BATCH_SIZE", 100),
		MaxRetries:           getEnvInt("MAX_RETRIES", 3),
		RetryBackoffMS:       getEnvInt("RETRY_BACKOFF_MS", 1000),
		ExcludedTables:       parseList(getEnv("EXCLUDED_TABLES", "")),
		MetricsPort:          getEnvInt("METRICS_PORT", 9090),
		HealthPort:           getEnvInt("HEALTH_PORT", 8081),
		SourceTimezone:       getEnv("SOURCE_DB_TIMEZONE", "UTC"),
		TargetTimezone:       getEnv("TARGET_DB_TIMEZONE", "UTC"),
	}

	// Validate target type
	if cfg.TargetType != TargetMySQL && cfg.TargetType != TargetPostgres {
		return nil, fmt.Errorf("invalid TARGET_TYPE %q: must be 'mysql' or 'postgres'", cfg.TargetType)
	}

	// Validate required fields based on target type
	if cfg.TargetType == TargetMySQL && cfg.TargetDB.Password == "" {
		return nil, fmt.Errorf("TARGET_DB_PASSWORD is required for MySQL target")
	}
	if cfg.TargetType == TargetPostgres && cfg.TargetPG.Password == "" {
		return nil, fmt.Errorf("TARGET_PG_PASSWORD is required for PostgreSQL target")
	}

	// Parse source timezone
	sourceLoc, err := time.LoadLocation(cfg.SourceTimezone)
	if err != nil {
		return nil, fmt.Errorf("invalid SOURCE_DB_TIMEZONE %s: %w", cfg.SourceTimezone, err)
	}
	cfg.SourceLocation = sourceLoc

	// Parse target timezone
	targetLoc, err := time.LoadLocation(cfg.TargetTimezone)
	if err != nil {
		return nil, fmt.Errorf("invalid TARGET_DB_TIMEZONE %s: %w", cfg.TargetTimezone, err)
	}
	cfg.TargetLocation = targetLoc

	return cfg, nil
}

// TargetDSN returns MySQL connection string
func (c *Config) TargetDSN() string {
	return fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?parseTime=true&loc=UTC",
		c.TargetDB.User,
		c.TargetDB.Password,
		c.TargetDB.Host,
		c.TargetDB.Port,
		c.TargetDB.Database,
	)
}

// TargetPostgresDSN returns PostgreSQL connection string for pgx driver.
// Uses the standard PostgreSQL connection URI format.
func (c *Config) TargetPostgresDSN() string {
	return fmt.Sprintf("postgres://%s:%s@%s:%d/%s?sslmode=%s&timezone=UTC",
		c.TargetPG.User,
		c.TargetPG.Password,
		c.TargetPG.Host,
		c.TargetPG.Port,
		c.TargetPG.Database,
		c.TargetPG.SSLMode,
	)
}

// TargetDatabase returns the database name based on target type.
func (c *Config) TargetDatabase() string {
	if c.TargetType == TargetPostgres {
		return c.TargetPG.Database
	}
	return c.TargetDB.Database
}

// IsTableExcluded checks if a table should be skipped
func (c *Config) IsTableExcluded(tableName string) bool {
	return slices.Contains(c.ExcludedTables, tableName)
}

// Helper: get env var with default
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// Helper: get env var as int with default
func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intVal, err := strconv.Atoi(value); err == nil {
			return intVal
		}
	}
	return defaultValue
}

// Helper: parse comma-separated list
func parseList(value string) []string {
	if value == "" {
		return nil
	}
	parts := strings.Split(value, ",")
	var result []string
	for _, p := range parts {
		if trimmed := strings.TrimSpace(p); trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}
