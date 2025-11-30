package writer

import (
	"database/sql"
	"fmt"
	_ "github.com/go-sql-driver/mysql"
	"time"

	"github.com/sparkiss/pos-cdc/internal/config"
	"github.com/sparkiss/pos-cdc/pkg/logger"
	"go.uber.org/zap"
)

type MySQLWriter struct {
	db         *sql.DB
	maxRetries int
	backoffMS  int
}

func New(cfg *config.Config) (*MySQLWriter, error) {

	db, err := sql.Open("mysql", cfg.TargetDSN())
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// TODO: Make these configurable
	db.SetMaxOpenConns(25)                 // Max open connections
	db.SetMaxIdleConns(5)                  // Max idle connections
	db.SetConnMaxLifetime(5 * time.Minute) // Max connection age

	// Test connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	logger.Log.Info("Connected to MySQL",

		zap.String("host", cfg.TargetDB.Host),
		zap.Int("port", cfg.TargetDB.Port),
		zap.String("database", cfg.TargetDB.Database))

	return &MySQLWriter{
		db:         db,
		maxRetries: cfg.MaxRetries,
		backoffMS:  cfg.RetryBackoffMS,
	}, nil
}

func (w *MySQLWriter) Execute(sqlStr string, args []any) error {
	var err error
	for attempt := 0; attempt <= w.maxRetries; attempt++ {
		if attempt > 0 {
			backoff := time.Duration(w.backoffMS*(1<<uint(attempt-1))) * time.Millisecond
			logger.Log.Warn("Retry %d/%d after %v",
				zap.Int("attempt", attempt),
				zap.Duration("backoff", backoff))
			time.Sleep(backoff)
		}

		_, err = w.db.Exec(sqlStr, args...)
		if err == nil {
			return nil // Success!
		}

		logger.Log.Error("Query faield",
			zap.Int("attempt", attempt),
			zap.Error(err))
	}

	return fmt.Errorf("failed after %d retries: %w", w.maxRetries, err)
}

func (w *MySQLWriter) Close() error {
	return w.db.Close()
}

func (w *MySQLWriter) Ping() error {
	return w.db.Ping()
}
