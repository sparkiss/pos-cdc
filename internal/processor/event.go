// Package processor handles CDC event processing and SQL generation.
package processor

import (
	"fmt"
	"strings"
	"time"

	"github.com/sparkiss/pos-cdc/internal/config"
	"github.com/sparkiss/pos-cdc/internal/models"
	"github.com/sparkiss/pos-cdc/internal/schema"
	"github.com/sparkiss/pos-cdc/pkg/logger"
	"go.uber.org/zap"
)

// Processor converts CDC events into database queries.
type Processor struct {
	schema     *schema.SchemaCache
	converter  *schema.Converter
	sqlBuilder SQLBuilder
	targetType config.TargetType
}

// New creates a Processor with the specified target type.
// Automatically selects the appropriate SQL builder based on target.
func New(schemaCache *schema.SchemaCache, sourceLocation, targetLocation *time.Location, targetType config.TargetType) *Processor {
	var builder SQLBuilder
	if targetType == config.TargetPostgres {
		builder = NewPostgresBuilder()
	} else {
		builder = NewMySQLBuilder()
	}

	return &Processor{
		schema:     schemaCache,
		converter:  schema.NewConverter(sourceLocation, targetLocation, targetType),
		sqlBuilder: builder,
		targetType: targetType,
	}
}

// BuildSQL converts a CDC event into a SQL query with parameters.
func (p *Processor) BuildSQL(event *models.CDCEvent) (string, []any, error) {
	tableSchema, err := p.schema.GetTableSchema(event.SourceTable)
	if err != nil {
		return "", nil, fmt.Errorf("schema lookup failed for %s: %w", event.SourceTable, err)
	}

	convertedPayload := p.convertPayload(event.Payload, tableSchema)

	op := event.GetOperation()

	logger.Log.Debug("Building query",
		zap.String("op", op.String()),
		zap.String("table", event.SourceTable),
		zap.String("target", string(p.targetType)))

	switch op {
	case models.OperationInsert:
		return p.sqlBuilder.BuildInsert(event.SourceTable, convertedPayload, tableSchema)
	case models.OperationUpdate:
		return p.sqlBuilder.BuildUpdate(event.SourceTable, convertedPayload, tableSchema)
	case models.OperationDelete:
		return p.sqlBuilder.BuildDelete(event.SourceTable, convertedPayload, tableSchema)
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
