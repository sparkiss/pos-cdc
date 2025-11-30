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

// Config holds all application configuration
type Config struct {
	// Database
	TargetDB DBConfig

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

	Timezone string
	Location *time.Location
}

// DBConfig holds database connection settings
type DBConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	Database string
}

// Load reads configuration from environment variables
// Looks for .env file first, then falls back to actual env vars
func Load() (*Config, error) {
	// Try to load .env file (ignore error if not found)
	// 📚 Search: "godotenv golang" for docs
	_ = godotenv.Load()

	cfg := &Config{
		TargetDB: DBConfig{
			Host:     getEnv("TARGET_DB_HOST", "localhost"),
			Port:     getEnvInt("TARGET_DB_PORT", 3307),
			User:     getEnv("TARGET_DB_USER", "root"),
			Password: getEnv("TARGET_DB_PASSWORD", ""),
			Database: getEnv("TARGET_DB_NAME", "pos"),
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
		Timezone:             getEnv("TIMEZONE", "UTC"),
	}

	// Validate required fields
	if cfg.TargetDB.Password == "" {
		return nil, fmt.Errorf("TARGET_DB_PASSWORD is required")
	}

	// Parse timezone
	loc, err := time.LoadLocation(cfg.Timezone)
	if err != nil {
		return nil, fmt.Errorf("invalid timezone %s: %w", cfg.Timezone, err)
	}
	cfg.Location = loc

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
