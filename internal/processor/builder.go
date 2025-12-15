package processor

import (
	"github.com/sparkiss/pos-cdc/internal/schema"
)

// SQLBuilder generates SQL statements for a specific database dialect.
// Implementations handle differences in quoting, placeholders, and upsert syntax.
type SQLBuilder interface {
	// BuildInsert creates an INSERT statement with upsert behavior.
	// For MySQL: INSERT ... ON DUPLICATE KEY UPDATE
	// For PostgreSQL: INSERT ... ON CONFLICT ... DO UPDATE
	BuildInsert(table string, payload map[string]any, tableSchema *schema.TableSchema) (string, []any, error)

	// BuildUpdate creates an UPDATE statement.
	BuildUpdate(table string, payload map[string]any, tableSchema *schema.TableSchema) (string, []any, error)

	// BuildDelete creates a soft-delete UPDATE statement (sets deleted_at).
	BuildDelete(table string, payload map[string]any, tableSchema *schema.TableSchema) (string, []any, error)
}
