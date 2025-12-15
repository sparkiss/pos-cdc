package processor

import (
	"fmt"
	"strings"
	"time"

	"github.com/sparkiss/pos-cdc/internal/schema"
)

// MySQLBuilder generates MySQL-specific SQL statements.
type MySQLBuilder struct{}

// NewMySQLBuilder creates a new MySQL SQL builder.
func NewMySQLBuilder() *MySQLBuilder {
	return &MySQLBuilder{}
}

// BuildInsert creates an INSERT ... ON DUPLICATE KEY UPDATE statement.
func (b *MySQLBuilder) BuildInsert(table string, payload map[string]any, tableSchema *schema.TableSchema) (string, []any, error) {
	var columns []string
	var placeholders []string
	var values []any
	var updateClauses []string

	for colName, value := range payload {
		if strings.HasPrefix(colName, "__") {
			continue
		}

		columns = append(columns, fmt.Sprintf("`%s`", colName))
		placeholders = append(placeholders, "?")
		values = append(values, value)

		// Skip primary keys in ON DUPLICATE KEY UPDATE
		if colInfo, ok := tableSchema.Columns[colName]; ok && !colInfo.IsPrimary {
			updateClauses = append(updateClauses, fmt.Sprintf("`%s` = VALUES(`%s`)", colName, colName))
		}
	}

	// Add deleted_at = NULL for upsert (un-delete if re-inserted)
	columns = append(columns, "`deleted_at`")
	placeholders = append(placeholders, "?")
	values = append(values, nil)
	updateClauses = append(updateClauses, "`deleted_at` = NULL")

	sql := fmt.Sprintf(
		"INSERT INTO `%s` (%s) VALUES (%s) ON DUPLICATE KEY UPDATE %s",
		table,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "),
		strings.Join(updateClauses, ", "),
	)

	return sql, values, nil
}

// BuildUpdate creates an UPDATE statement with MySQL syntax.
func (b *MySQLBuilder) BuildUpdate(table string, payload map[string]any, tableSchema *schema.TableSchema) (string, []any, error) {
	var setClauses []string
	var values []any
	var pkValues []any

	for colName, value := range payload {
		if strings.HasPrefix(colName, "__") {
			continue
		}

		colInfo, exists := tableSchema.Columns[colName]
		if exists && colInfo.IsPrimary {
			pkValues = append(pkValues, value)
			continue
		}

		setClauses = append(setClauses, fmt.Sprintf("`%s` = ?", colName))
		values = append(values, value)
	}

	if len(tableSchema.PrimaryKeys) == 0 {
		return "", nil, fmt.Errorf("no primary key for table %s", table)
	}

	if len(pkValues) != len(tableSchema.PrimaryKeys) {
		return "", nil, fmt.Errorf("missing primary key values in payload")
	}

	// If no non-PK columns to update, skip the update
	// This can happen if CDC sends an update event with only PK columns
	if len(setClauses) == 0 {
		return "", nil, fmt.Errorf("no columns to update for table %s (only primary key columns in payload)", table)
	}

	var whereClauses []string
	for _, pk := range tableSchema.PrimaryKeys {
		whereClauses = append(whereClauses, fmt.Sprintf("`%s` = ?", pk))
	}
	values = append(values, pkValues...)

	sql := fmt.Sprintf(
		"UPDATE `%s` SET %s WHERE %s",
		table,
		strings.Join(setClauses, ", "),
		strings.Join(whereClauses, " AND "),
	)

	return sql, values, nil
}

// BuildDelete creates a soft-delete UPDATE statement.
func (b *MySQLBuilder) BuildDelete(table string, payload map[string]any, tableSchema *schema.TableSchema) (string, []any, error) {
	if len(tableSchema.PrimaryKeys) == 0 {
		return "", nil, fmt.Errorf("no primary key for table %s", table)
	}

	var pkValues []any
	for _, pk := range tableSchema.PrimaryKeys {
		if value, ok := payload[pk]; ok {
			pkValues = append(pkValues, value)
		}
	}

	if len(pkValues) != len(tableSchema.PrimaryKeys) {
		return "", nil, fmt.Errorf("missing primary key values for soft delete")
	}

	var whereClauses []string
	for _, pk := range tableSchema.PrimaryKeys {
		whereClauses = append(whereClauses, fmt.Sprintf("`%s` = ?", pk))
	}

	sql := fmt.Sprintf(
		"UPDATE `%s` SET `deleted_at` = ? WHERE %s",
		table,
		strings.Join(whereClauses, " AND "),
	)

	values := []any{time.Now().UTC()}
	values = append(values, pkValues...)

	return sql, values, nil
}
