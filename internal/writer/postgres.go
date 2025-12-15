package writer

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib"

	"github.com/sparkiss/pos-cdc/internal/config"
	"github.com/sparkiss/pos-cdc/internal/metrics"
	"github.com/sparkiss/pos-cdc/pkg/logger"
	"go.uber.org/zap"
)

// PostgresWriter implements the Writer interface for PostgreSQL databases.
type PostgresWriter struct {
	db         *sql.DB
	maxRetries int
	backoffMS  int
}

// Compile-time check that PostgresWriter implements Writer interface.
var _ Writer = (*PostgresWriter)(nil)

// NewPostgres creates a new PostgreSQL writer from configuration.
func NewPostgres(cfg *config.Config) (*PostgresWriter, error) {
	db, err := sql.Open("pgx", cfg.TargetPostgresDSN())
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	logger.Log.Info("Connected to PostgreSQL",
		zap.String("host", cfg.TargetPG.Host),
		zap.Int("port", cfg.TargetPG.Port),
		zap.String("database", cfg.TargetPG.Database))

	return &PostgresWriter{
		db:         db,
		maxRetries: cfg.MaxRetries,
		backoffMS:  cfg.RetryBackoffMS,
	}, nil
}

// ExecuteBatch executes multiple queries in a single transaction with retry logic.
func (w *PostgresWriter) ExecuteBatch(queries []Query) error {
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

		if !isPostgresDeadlock(err) {
			for _, q := range queries {
				metrics.EventsFailed.WithLabelValues(q.Table, q.Op, "execution_error").Inc()
			}
			return err
		}

		metrics.EventsFailed.WithLabelValues("batch", "transaction", "deadlock").Inc()
	}

	for _, q := range queries {
		metrics.EventsFailed.WithLabelValues(q.Table, q.Op, "deadlock_exhausted").Inc()
	}
	return fmt.Errorf("deadlock persisted after %d retries: %w", w.maxRetries, err)
}

func (w *PostgresWriter) executeBatchOnce(queries []Query) error {
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
				zap.String("sql", q.SQL),
				zap.Error(err))
			return fmt.Errorf("failed to execute %s on %s: %w", q.Op, q.Table, err)
		}
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit batch: %w", err)
	}

	duration := time.Since(start).Seconds()
	for _, q := range queries {
		metrics.EventsProcessed.WithLabelValues(q.Table, q.Op).Inc()
		metrics.QueryDuration.WithLabelValues(q.Table, q.Op).Observe(duration / float64(len(queries)))
	}

	logger.Log.Debug("Batch committed",
		zap.Int("count", len(queries)))

	return nil
}

// isPostgresDeadlock checks if the error is a PostgreSQL deadlock.
// PostgreSQL uses SQLSTATE 40P01 for deadlock_detected.
func isPostgresDeadlock(err error) bool {
	if err == nil {
		return false
	}
	errStr := err.Error()
	return strings.Contains(errStr, "40P01") ||
		strings.Contains(errStr, "deadlock detected")
}

func (w *PostgresWriter) Close() error {
	return w.db.Close()
}

func (w *PostgresWriter) Ping() error {
	return w.db.Ping()
}

func (w *PostgresWriter) DB() *sql.DB {
	return w.db
}
