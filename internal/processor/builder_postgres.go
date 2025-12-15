package processor

import (
	"fmt"
	"strings"
	"time"

	"github.com/sparkiss/pos-cdc/internal/schema"
)

// PostgresBuilder generates PostgreSQL-specific SQL statements.
type PostgresBuilder struct{}

// NewPostgresBuilder creates a new PostgreSQL SQL builder.
func NewPostgresBuilder() *PostgresBuilder {
	return &PostgresBuilder{}
}

// BuildInsert creates an INSERT ... ON CONFLICT ... DO UPDATE statement.
func (b *PostgresBuilder) BuildInsert(table string, payload map[string]any, tableSchema *schema.TableSchema) (string, []any, error) {
	var columns []string
	var placeholders []string
	var values []any
	var updateClauses []string
	paramIdx := 1

	for colName, value := range payload {
		if strings.HasPrefix(colName, "__") {
			continue
		}

		columns = append(columns, fmt.Sprintf(`"%s"`, colName))
		placeholders = append(placeholders, fmt.Sprintf("$%d", paramIdx))
		values = append(values, value)
		paramIdx++

		// Skip primary keys in ON CONFLICT DO UPDATE
		if colInfo, ok := tableSchema.Columns[colName]; ok && !colInfo.IsPrimary {
			updateClauses = append(updateClauses, fmt.Sprintf(`"%s" = EXCLUDED."%s"`, colName, colName))
		}
	}

	// Add deleted_at = NULL for upsert (un-delete if re-inserted)
	columns = append(columns, `"deleted_at"`)
	placeholders = append(placeholders, fmt.Sprintf("$%d", paramIdx))
	values = append(values, nil)
	updateClauses = append(updateClauses, `"deleted_at" = NULL`)

	// Build ON CONFLICT clause with primary key columns
	var pkColumns []string
	for _, pk := range tableSchema.PrimaryKeys {
		pkColumns = append(pkColumns, fmt.Sprintf(`"%s"`, pk))
	}

	if len(pkColumns) == 0 {
		return "", nil, fmt.Errorf("no primary key for table %s", table)
	}

	sql := fmt.Sprintf(
		`INSERT INTO "%s" (%s) VALUES (%s) ON CONFLICT (%s) DO UPDATE SET %s`,
		table,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "),
		strings.Join(pkColumns, ", "),
		strings.Join(updateClauses, ", "),
	)

	return sql, values, nil
}

// BuildUpdate creates an UPDATE statement with PostgreSQL syntax.
func (b *PostgresBuilder) BuildUpdate(table string, payload map[string]any, tableSchema *schema.TableSchema) (string, []any, error) {
	var setClauses []string
	var values []any
	var pkValues []any
	paramIdx := 1

	for colName, value := range payload {
		if strings.HasPrefix(colName, "__") {
			continue
		}

		colInfo, exists := tableSchema.Columns[colName]
		if exists && colInfo.IsPrimary {
			pkValues = append(pkValues, value)
			continue
		}

		setClauses = append(setClauses, fmt.Sprintf(`"%s" = $%d`, colName, paramIdx))
		values = append(values, value)
		paramIdx++
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
		whereClauses = append(whereClauses, fmt.Sprintf(`"%s" = $%d`, pk, paramIdx))
		paramIdx++
	}
	values = append(values, pkValues...)

	sql := fmt.Sprintf(
		`UPDATE "%s" SET %s WHERE %s`,
		table,
		strings.Join(setClauses, ", "),
		strings.Join(whereClauses, " AND "),
	)

	return sql, values, nil
}

// BuildDelete creates a soft-delete UPDATE statement.
func (b *PostgresBuilder) BuildDelete(table string, payload map[string]any, tableSchema *schema.TableSchema) (string, []any, error) {
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
	paramIdx := 2 // $1 is deleted_at value
	for _, pk := range tableSchema.PrimaryKeys {
		whereClauses = append(whereClauses, fmt.Sprintf(`"%s" = $%d`, pk, paramIdx))
		paramIdx++
	}

	sql := fmt.Sprintf(
		`UPDATE "%s" SET "deleted_at" = $1 WHERE %s`,
		table,
		strings.Join(whereClauses, " AND "),
	)

	values := []any{time.Now().UTC()}
	values = append(values, pkValues...)

	return sql, values, nil
}
