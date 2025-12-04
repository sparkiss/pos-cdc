package writer

import (
	"fmt"

	"go.uber.org/zap"

	"github.com/sparkiss/pos-cdc/pkg/logger"
)

// Query represents a single database operation
type Query struct {
	SQL   string
	Args  []any
	Table string
	Op    string
}

// ExecuteBatch executes multiple queries in a single transaction
func (w *MySQLWriter) ExecuteBatch(queries []Query) error {
	if len(queries) == 0 {
		return nil
	}

	tx, err := w.db.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}

	for i, q := range queries {
		_, err := tx.Exec(q.SQL, q.Args...)
		if err != nil {
			tx.Rollback()
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

	logger.Log.Debug("Batch committed",
		zap.Int("count", len(queries)))

	return nil
}
