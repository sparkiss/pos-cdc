package schema

import (
	"fmt"
	"time"
)

type Converter struct {
	sourceLocation *time.Location
	targetLocation *time.Location
}

func NewConverter(sourceLoc, targetLoc *time.Location) *Converter {
	if sourceLoc == nil {
		sourceLoc = time.UTC
	}
	if targetLoc == nil {
		targetLoc = time.UTC
	}
	return &Converter{
		sourceLocation: sourceLoc,
		targetLocation: targetLoc,
	}
}

// ConvertValue converts a Debezium payload value to the appropriate Go type
// based on the target column's data type
func (c *Converter) ConvertValue(colInfo *ColumnInfo, value any) any {
	if value == nil {
		return nil
	}

	switch colInfo.DataType {
	// Temporal types
	case "datetime", "timestamp":
		return c.convertToDateTime(value)
	case "date":
		return c.convertToDate(value)
	case "time":
		return c.convertToTime(value)

	// Numeric types - pass through (MySQL handles string->number)
	case "int", "bigint", "smallint", "tinyint", "mediumint":
		return value
	case "decimal", "numeric", "float", "double":
		return value

	// String types - pass through
	case "varchar", "char", "text", "longtext", "mediumtext", "tinytext":
		return value

	// Binary types - pass through (Debezium handles based on binary.handling.mode)
	case "blob", "longblob", "mediumblob", "tinyblob", "binary", "varbinary":
		return value

	// Boolean
	case "bit", "bool", "boolean":
		return c.convertToBool(value)

	// JSON
	case "json":
		return value

	default:
		// Unknown type - pass through
		return value
	}
}

func (c *Converter) convertToDateTime(value any) any {
	switch v := value.(type) {
	case float64:
		return c.epochToMySQLDateTime(int64(v))
	case int64:
		return c.epochToMySQLDateTime(v)
	case int:
		return c.epochToMySQLDateTime(int64(v))
	case string:
		// With time.precision.mode=connect, strings shouldn't happen
		// but pass through if they do (already formatted)
		return v
	}
	return value
}

func (c *Converter) epochToMySQLDateTime(v int64) string {
	// Debezium time.precision.mode=connect sends datetime/timestamp as epoch ms.
	// However, source DB stores local time without timezone info.
	// Debezium interprets this as UTC, so the epoch represents the wall-clock
	// time as if it were UTC.
	//
	// Step 1: Get UTC time from epoch (this gives us the wall-clock values)
	utcTime := time.UnixMilli(v)

	// Step 2: Treat those wall-clock values as source timezone
	// (e.g., "12:00" in source DB was Mountain Time, not UTC)
	sourceWallClock := time.Date(
		utcTime.Year(), utcTime.Month(), utcTime.Day(),
		utcTime.Hour(), utcTime.Minute(), utcTime.Second(),
		utcTime.Nanosecond(), c.sourceLocation,
	)

	// Step 3: Convert to target timezone
	targetTime := sourceWallClock.In(c.targetLocation)

	return targetTime.Format("2006-01-02 15:04:05")
}

func (c *Converter) convertToDate(value any) any {
	switch v := value.(type) {
	case float64:
		return c.daysToMySQLDate(int64(v))
	case int64:
		return c.daysToMySQLDate(v)
	case int:
		return c.daysToMySQLDate(int64(v))
	case string:
		return v
	}
	return value
}

func (c *Converter) daysToMySQLDate(days int64) string {
	// Debezium time.precision.mode=connect sends date as days since epoch.
	// Since dates have no time component, we interpret midnight UTC
	// then apply timezone conversion which may shift the date.
	//
	// Step 1: Get the date at midnight UTC
	utcTime := time.Unix(days*86400, 0).UTC()

	// Step 2: Treat as source timezone midnight
	sourceDate := time.Date(
		utcTime.Year(), utcTime.Month(), utcTime.Day(),
		0, 0, 0, 0, c.sourceLocation,
	)

	// Step 3: Convert to target timezone (date may shift if TZ offset differs)
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

// convertToBool handles boolean/bit columns
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
