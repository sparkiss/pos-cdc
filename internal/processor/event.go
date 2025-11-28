package processor

import (
	"fmt"
	"strings"
	"time"

	"github.com/sparkiss/pos-cdc/internal/models"
)

type Processor struct {
	// TODO: Add schema cache for PK lookup
	// for now, we assume "id" is the PK

}

func New() *Processor {
	return &Processor{}
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
		// Skip Debezium metadata fields
		if strings.HasPrefix(key, "__") {
			continue
		}

		columns = append(columns, fmt.Sprintf("`%s`", key))
		placeholders = append(placeholders, "?")
		values = append(values, value)

		// For ON DUPLICATE KEY UPDATE (skip primary key)
		if key != "id" {
			updateClauses = append(updateClauses, fmt.Sprintf("`%s` = VALUES(`%s`)", key, key))
		}
	}

	// Add deleted_at = NULL (clear soft delete on insert/re-insert)
	columns = append(columns, "`deleted_at`")
	placeholders = append(placeholders, "?")
	values = append(values, nil)
	updateClauses = append(updateClauses, "`deleted_at` = NULL")

	// Build the SQL
	// FIXME: Table name should be properly escaped/validated
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
	var values []interface{}
	var primaryKey string
	var primaryValue interface{}

	for key, value := range event.Payload {
		// Skip metadata
		if strings.HasPrefix(key, "__") {
			continue
		}

		// FIXME: Hardcoded primary key assumption
		// TODO: Look up actual primary key from information_schema
		if key == "id" {
			primaryKey = key
			primaryValue = value
			continue
		}

		setClauses = append(setClauses, fmt.Sprintf("`%s` = ?", key))
		values = append(values, value)
	}

	if primaryKey == "" {
		return "", nil, fmt.Errorf("no primary key found in event")
	}

	// Add primary key value for WHERE clause
	values = append(values, primaryValue)

	sql := fmt.Sprintf(
		"UPDATE `%s` SET %s WHERE `%s` = ?",
		event.SourceTable,
		strings.Join(setClauses, ", "),
		primaryKey,
	)

	return sql, values, nil
}

// buildSoftDelete creates an UPDATE that sets deleted_at
// This is the key difference: source does DELETE, we do soft delete
func (p *Processor) buildInsert(event *models.CDCEvent) (string, []any, error) {
	// Find the primary key in the payload
	var primaryKey string
	var primaryValue any

	for key, value := range event.Payload {
		// FIXME: Hardcoded - should lookup actual PK
		if key == "id" {
			primaryKey = key
			primaryValue = value
			break
		}
	}

	if primaryKey == "" {
		return "", nil, fmt.Errorf("no primary key found for delete")
	}

	// Soft delete: set deleted_at to current time
	sql := fmt.Sprintf(
		"UPDATE `%s` SET `deleted_at` = ? WHERE `%s` = ?",
		event.SourceTable,
		primaryKey,
	)

	values := []any{
		time.Now().UTC(), // deleted_at timestamp
		primaryValue,     // WHERE id = ?
	}

	return sql, values, nil
}
