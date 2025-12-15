package writer

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql"

	"github.com/sparkiss/pos-cdc/internal/config"
	"github.com/sparkiss/pos-cdc/internal/metrics"
	"github.com/sparkiss/pos-cdc/pkg/logger"
	"go.uber.org/zap"
)

// MySQLWriter implements the Writer interface for MySQL databases.
type MySQLWriter struct {
	db         *sql.DB
	maxRetries int
	backoffMS  int
}

// Compile-time check that MySQLWriter implements Writer interface.
var _ Writer = (*MySQLWriter)(nil)

// NewMySQL creates a new MySQL writer from configuration.
func NewMySQL(cfg *config.Config) (*MySQLWriter, error) {
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

// ExecuteBatch executes multiple queries in a single transaction with retry
func (w *MySQLWriter) ExecuteBatch(queries []Query) error {
	if len(queries) == 0 {
		return nil
	}

	var err error
	for attempt := 0; attempt <= w.maxRetries; attempt++ {
		if attempt > 0 {
			// #nosec G115 - attempt is bounded by maxRetries (typically < 10), no overflow risk
			backoff := time.Duration(w.backoffMS*(1<<uint(attempt-1))) * time.Millisecond
			logger.Log.Warn("Retrying batch after error",
				zap.Int("attempt", attempt),
				zap.Duration("backoff", backoff),
				zap.Error(err))
			time.Sleep(backoff)
		}

		err = w.executeBatchOnce(queries)
		if err == nil {
			if attempt > 0 {
				logger.Log.Info("Batch succeeded after retry",
					zap.Int("attempts", attempt+1))
			}
			return nil
		}

		// Only retry on deadlock errors
		if !isDeadlock(err) {
			// Non-retryable error, fail immediately
			for _, q := range queries {
				metrics.EventsFailed.WithLabelValues(q.Table, q.Op, "execution_error").Inc()
			}
			return err
		}

		// Record deadlock metric
		metrics.EventsFailed.WithLabelValues("batch", "transaction", "deadlock").Inc()
	}

	// All retries exhausted
	for _, q := range queries {
		metrics.EventsFailed.WithLabelValues(q.Table, q.Op, "deadlock_exhausted").Inc()
	}
	return fmt.Errorf("deadlock persisted after %d retries: %w", w.maxRetries, err)
}

// executeBatchOnce executes the batch without retry logic
func (w *MySQLWriter) executeBatchOnce(queries []Query) error {
	start := time.Now()

	tx, err := w.db.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}

	for i, q := range queries {
		_, err := tx.Exec(q.SQL, q.Args...)
		if err != nil {
			_ = tx.Rollback()
			logger.Log.Error("Batch query failed",
				zap.Int("index", i),
				zap.String("table", q.Table),
				zap.String("op", q.Op),
				zap.Error(err))
			return fmt.Errorf("failed to execute %s on %s: %w", q.Op, q.Table, err)
		}
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit batch: %w", err)
	}

	// Record success metrics
	duration := time.Since(start).Seconds()
	for _, q := range queries {
		metrics.EventsProcessed.WithLabelValues(q.Table, q.Op).Inc()
		metrics.QueryDuration.WithLabelValues(q.Table, q.Op).Observe(duration / float64(len(queries)))
	}

	logger.Log.Debug("Batch committed",
		zap.Int("count", len(queries)))

	return nil
}

// isDeadlock checks if the error is a MySQL deadlock
func isDeadlock(err error) bool {
	if err == nil {
		return false
	}
	errStr := err.Error()
	return strings.Contains(errStr, "Error 1213") ||
		strings.Contains(errStr, "Deadlock found")
}

func (w *MySQLWriter) Close() error {
	return w.db.Close()
}

func (w *MySQLWriter) Ping() error {
	return w.db.Ping()
}

func (w *MySQLWriter) DB() *sql.DB {
	return w.db
}
