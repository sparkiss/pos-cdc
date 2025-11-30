package processor

import (
	"fmt"
	"github.com/sparkiss/pos-cdc/internal/models"
	"github.com/sparkiss/pos-cdc/internal/schema"
	"strings"
	"time"
)

type Processor struct {
	schema *schema.SchemaCache
}

func New(schemaCache *schema.SchemaCache) *Processor {
	return &Processor{
		schema: schemaCache,
	}
}

func (p *Processor) BuildSQL(event *models.CDCEvent) (string, []any, error) {
	op := event.GetOperation()

	switch op {
	case models.OperationInsert:
		return p.buildInsert(event)
	case models.OperationUpdate:
		return p.buildUpdate(event)
	case models.OperationDelete:
		return p.buildDelete(event)
	default:
		return "", nil, fmt.Errorf("unknown operation: %s", event.Operation)

	}
}

func (p *Processor) buildDelete(event *models.CDCEvent) (string, []any, error) {
	var columns []string
	var placeholders []string
	var values []any
	var updateClauses []string

	for key, value := range event.Payload {
		if strings.HasPrefix(key, "__") {
			continue
		}

		columns = append(columns, fmt.Sprintf("`%s`", key))
		placeholders = append(placeholders, "?")
		values = append(values, value)

		// Skip primary key in ON DUPLICATE KEY UPDATE
		if !p.schema.IsPrimaryKey(event.SourceTable, key) {
			updateClauses = append(updateClauses, fmt.Sprintf("`%s` = VALUES(`%s`)", key, key))
		}
	}

	columns = append(columns, "`deleted_at`")
	placeholders = append(placeholders, "?")
	values = append(values, nil)
	updateClauses = append(updateClauses, "`deleted_at` = NULL")

	sql := fmt.Sprintf(
		"INSERT INTO `%s` (%s) VALUES (%s) ON DUPLICATE KEY UPDATE %s",
		event.SourceTable,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "),
		strings.Join(updateClauses, ", "),
	)

	return sql, values, nil
}

func (p *Processor) buildUpdate(event *models.CDCEvent) (string, []any, error) {
	var setClauses []string
	var values []any
	var pkValues []any

	// Get primary keys for this table
	pks, err := p.schema.GetPrimaryKeys(event.SourceTable)
	if err != nil {
		return "", nil, fmt.Errorf("failed to get primary keys: %w", err)
	}

	// Helper to check if column is PK
	isPK := func(col string) bool {
		for _, pk := range pks {
			if pk == col {
				return true
			}
		}
		return false
	}

	for key, value := range event.Payload {
		if strings.HasPrefix(key, "__") {
			continue
		}

		// Check if this column is a primary key
		if isPK(key) {
			pkValues = append(pkValues, value)
			continue
		}

		setClauses = append(setClauses, fmt.Sprintf("`%s` = ?", key))
		values = append(values, value)
	}

	if len(pkValues) != len(pks) {
		return "", nil, fmt.Errorf("missing primary key values in event")
	}

	// Build WHERE clause (supports composite keys)
	var whereClauses []string
	for _, pk := range pks {
		whereClauses = append(whereClauses, fmt.Sprintf("`%s` = ?", pk))
	}
	values = append(values, pkValues...)

	sql := fmt.Sprintf(
		"UPDATE `%s` SET %s WHERE %s",
		event.SourceTable,
		strings.Join(setClauses, ", "),
		strings.Join(whereClauses, " AND "),
	)

	return sql, values, nil
}

// buildSoftDelete creates an UPDATE that sets deleted_at
// This is the key difference: source does DELETE, we do soft delete
func (p *Processor) buildInsert(event *models.CDCEvent) (string, []any, error) {
	// Get primary keys for this table
	pks, err := p.schema.GetPrimaryKeys(event.SourceTable)
	if err != nil {
		return "", nil, fmt.Errorf("failed to get primary keys: %w", err)
	}

	// Find primary key values in payload
	var pkValues []any
	for _, pk := range pks {
		if value, ok := event.Payload[pk]; ok {
			pkValues = append(pkValues, value)
		}
	}

	if len(pkValues) != len(pks) {
		return "", nil, fmt.Errorf("missing primary key values for soft delete")
	}

	// Build WHERE clause using pks order
	var whereClauses []string
	for _, pk := range pks {
		whereClauses = append(whereClauses, fmt.Sprintf("`%s` = ?", pk))
	}

	sql := fmt.Sprintf(
		"UPDATE `%s` SET `deleted_at` = ? WHERE %s",
		event.SourceTable,
		strings.Join(whereClauses, " AND "),
	)

	values := []any{time.Now().UTC()}
	values = append(values, pkValues...)

	return sql, values, nil
}
