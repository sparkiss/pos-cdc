package processor

import (
	"fmt"
	"github.com/sparkiss/pos-cdc/internal/models"
	"github.com/sparkiss/pos-cdc/internal/schema"
	"github.com/sparkiss/pos-cdc/pkg/logger"
	"go.uber.org/zap"
	"strings"
	"time"
)

type Processor struct {
	schema    *schema.SchemaCache
	converter *schema.Converter
}

func New(schemaCache *schema.SchemaCache, location *time.Location) *Processor {
	return &Processor{
		schema:    schemaCache,
		converter: schema.NewConverter(location),
	}
}

func (p *Processor) BuildSQL(event *models.CDCEvent) (string, []any, error) {
	// Get table schema (lazy loaded, cached)
	tableSchema, err := p.schema.GetTableSchema(event.SourceTable)
	if err != nil {
		return "", nil, fmt.Errorf("schema lookup failed for %s: %w", event.SourceTable, err)
	}

	// Convert payload values based on column types
	convertedPayload := p.convertPayload(event.Payload, tableSchema)

	op := event.GetOperation()

	logger.Log.Debug("Before build query", zap.String("op", op.String()), zap.Any("payload", event.Payload))

	switch op {
	case models.OperationInsert:
		return p.buildInsert(event.SourceTable, convertedPayload, tableSchema)
	case models.OperationUpdate:
		return p.buildUpdate(event.SourceTable, convertedPayload, tableSchema)
	case models.OperationDelete:
		return p.buildDelete(event.SourceTable, convertedPayload, tableSchema)
	default:
		return "", nil, fmt.Errorf("unknown operation: %s", event.Operation)
	}
}

func (p *Processor) convertPayload(payload map[string]any, tableSchema *schema.TableSchema) map[string]any {
	converted := make(map[string]any, len(payload))

	for colName, value := range payload {
		if strings.HasPrefix(colName, "__") {
			converted[colName] = value
			continue
		}

		if colInfo, ok := tableSchema.Columns[colName]; ok {
			converted[colName] = p.converter.ConvertValue(colInfo, value)
		} else {
			converted[colName] = value
		}
	}

	logger.Log.Debug("Payload converted", zap.Any("converted", converted))

	return converted
}

func (p *Processor) buildDelete(table string, payload map[string]any, tableSchema *schema.TableSchema) (string, []any, error) {
	if len(tableSchema.PrimaryKeys) == 0 {
		return "", nil, fmt.Errorf("no primary key for table %s", table)
	}

	// Find primary key values in payload
	var pkValues []any
	for _, pk := range tableSchema.PrimaryKeys {
		if value, ok := payload[pk]; ok {
			pkValues = append(pkValues, value)
		}
	}

	if len(pkValues) != len(tableSchema.PrimaryKeys) {
		return "", nil, fmt.Errorf("missing primary key values for soft delete")
	}

	// Build WHERE clause
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

func (p *Processor) buildUpdate(table string, payload map[string]any, tableSchema *schema.TableSchema) (string, []any, error) {
	var setClauses []string
	var values []any
	var pkValues []any

	for colName, value := range payload {
		if strings.HasPrefix(colName, "__") {
			continue
		}

		// Check if this is a primary key column
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

	// Build WHERE clause
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

// buildSoftDelete creates an UPDATE that sets deleted_at
// This is the key difference: source does DELETE, we do soft delete
// buildInsert creates an INSERT ... ON DUPLICATE KEY UPDATE statement
func (p *Processor) buildInsert(table string, payload map[string]any, tableSchema *schema.TableSchema) (string, []any, error) {
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
