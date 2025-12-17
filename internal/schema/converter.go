package schema

import (
	"fmt"
	"time"

	"github.com/sparkiss/pos-cdc/internal/config"
)

// Converter handles Debezium value conversion for different target databases.
type Converter struct {
	sourceLocation *time.Location
	targetLocation *time.Location
	targetType     config.TargetType
}

// NewConverter creates a converter for the specified source and target timezones.
// The targetType determines the output format for datetime columns.
func NewConverter(sourceLoc, targetLoc *time.Location, targetType config.TargetType) *Converter {
	if sourceLoc == nil {
		sourceLoc = time.UTC
	}
	if targetLoc == nil {
		targetLoc = time.UTC
	}
	return &Converter{
		sourceLocation: sourceLoc,
		targetLocation: targetLoc,
		targetType:     targetType,
	}
}

// ConvertValue converts a Debezium payload value to the appropriate Go type
// based on the target column's data type and target database.
func (c *Converter) ConvertValue(colInfo *ColumnInfo, value any) any {
	if value == nil {
		return nil
	}

	switch colInfo.DataType {
	// Temporal types - MySQL: datetime, timestamp; PostgreSQL: timestamp with/without time zone
	// Include PostgreSQL aliases: timestamptz, timetz
	case "datetime", "timestamp", "timestamp with time zone", "timestamp without time zone", "timestamptz":
		return c.convertToDateTime(value)
	case "date":
		return c.convertToDate(value)
	case "time", "time with time zone", "time without time zone", "timetz":
		return c.convertToTime(value)

	// Numeric types - pass through
	// MySQL: int, bigint, etc.; PostgreSQL: integer, bigint, smallint
	case "int", "integer", "bigint", "smallint", "tinyint", "mediumint":
		return value
	case "decimal", "numeric", "float", "double", "double precision", "real":
		return value

	// String types - pass through
	// MySQL: varchar, char, text; PostgreSQL: character varying, character, text
	case "varchar", "char", "text", "longtext", "mediumtext", "tinytext", "character varying", "character":
		return value

	// Binary types - pass through
	// MySQL: blob, binary; PostgreSQL: bytea
	case "blob", "longblob", "mediumblob", "tinyblob", "binary", "varbinary", "bytea":
		return value

	// Boolean
	// MySQL: bit, bool; PostgreSQL: boolean
	case "bit", "bool", "boolean":
		return c.convertToBool(value)

	// JSON - MySQL: json; PostgreSQL: json, jsonb
	case "json", "jsonb":
		return value

	default:
		return value
	}
}

func (c *Converter) convertToDateTime(value any) any {
	switch v := value.(type) {
	case float64:
		return c.epochToDateTime(int64(v))
	case int64:
		return c.epochToDateTime(v)
	case int:
		return c.epochToDateTime(int64(v))
	case string:
		return c.parseISO8601DateTime(v)
	}
	return value
}

// epochToDateTime converts epoch milliseconds to the appropriate format.
// For MySQL: returns string "2006-01-02 15:04:05"
// For PostgreSQL: returns time.Time with source timezone (pgx handles TZ)
func (c *Converter) epochToDateTime(v int64) any {
	// Debezium time.precision.mode=connect sends datetime/timestamp as epoch ms.
	// Source DB stores local time without timezone info.
	// Debezium interprets this as UTC, so the epoch represents the wall-clock
	// time as if it were UTC.
	//
	// Step 1: Get UTC time from epoch (this gives us the wall-clock values)
	utcTime := time.UnixMilli(v)

	// Step 2: Treat those wall-clock values as source timezone
	sourceWallClock := time.Date(
		utcTime.Year(), utcTime.Month(), utcTime.Day(),
		utcTime.Hour(), utcTime.Minute(), utcTime.Second(),
		utcTime.Nanosecond(), c.sourceLocation,
	)

	// For PostgreSQL: return time.Time with timezone info
	// The pgx driver will send this with the offset, and PostgreSQL stores as UTC
	if c.targetType == config.TargetPostgres {
		return sourceWallClock
	}

	// For MySQL: convert to target timezone and format as string
	targetTime := sourceWallClock.In(c.targetLocation)
	return targetTime.Format("2006-01-02 15:04:05")
}

// parseISO8601DateTime parses ISO8601 string and converts appropriately.
func (c *Converter) parseISO8601DateTime(s string) any {
	formats := []string{
		time.RFC3339,
		"2006-01-02T15:04:05Z",
		"2006-01-02T15:04:05",
		"2006-01-02 15:04:05",
	}

	for _, format := range formats {
		if t, err := time.Parse(format, s); err == nil {
			// If parsed time has no timezone info, assume source timezone
			if format == "2006-01-02T15:04:05" || format == "2006-01-02 15:04:05" {
				t = time.Date(t.Year(), t.Month(), t.Day(), t.Hour(), t.Minute(), t.Second(), t.Nanosecond(), c.sourceLocation)
			}

			// For PostgreSQL: return time.Time
			if c.targetType == config.TargetPostgres {
				return t
			}

			// For MySQL: format as string in target timezone
			return t.In(c.targetLocation).Format("2006-01-02 15:04:05")
		}
	}

	return s
}

func (c *Converter) convertToDate(value any) any {
	switch v := value.(type) {
	case float64:
		return c.daysToDate(int64(v))
	case int64:
		return c.daysToDate(v)
	case int:
		return c.daysToDate(int64(v))
	case string:
		return v
	}
	return value
}

func (c *Converter) daysToDate(days int64) any {
	// Debezium sends date as days since epoch
	utcTime := time.Unix(days*86400, 0).UTC()

	sourceDate := time.Date(
		utcTime.Year(), utcTime.Month(), utcTime.Day(),
		0, 0, 0, 0, c.sourceLocation,
	)

	// For PostgreSQL: return time.Time (DATE columns accept time.Time)
	if c.targetType == config.TargetPostgres {
		return sourceDate
	}

	// For MySQL: format as string
	targetDate := sourceDate.In(c.targetLocation)
	return targetDate.Format("2006-01-02")
}

func (c *Converter) convertToTime(value any) any {
	switch v := value.(type) {
	case float64:
		return millisToTimeString(int64(v))
	case int64:
		return millisToTimeString(v)
	case string:
		return v
	}
	return value
}

func millisToTimeString(ms int64) string {
	if ms < 0 {
		ms = 0
	}
	hours := ms / 3600000
	ms %= 3600000
	mins := ms / 60000
	ms %= 60000
	secs := ms / 1000
	return fmt.Sprintf("%02d:%02d:%02d", hours, mins, secs)
}

func (c *Converter) convertToBool(value any) any {
	switch v := value.(type) {
	case bool:
		return v
	case float64:
		return v != 0
	case int64:
		return v != 0
	case int:
		return v != 0
	case string:
		return v == "1" || v == "true" || v == "TRUE"
	default:
		return value
	}
}
