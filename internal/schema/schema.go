package schema

import (
	"database/sql"
	"fmt"
	//"slices"
	"sync"
)

// ColumnInfo holds metadata for a single column
type ColumnInfo struct {
	Name       string
	DataType   string // datetime, timestamp, decimal, varchar, int, bigint, etc.
	IsNullable bool
	IsPrimary  bool
}

// TableSchema holds all metadata for a table
type TableSchema struct {
	Name        string
	Columns     map[string]*ColumnInfo // column name -> info
	PrimaryKeys []string               // ordered list of PK columns
}

// SchemaCache caches primary key information to avoid repeated database queries
type SchemaCache struct {
	db     *sql.DB
	dbName string
	cache  map[string]*TableSchema
	mu     sync.RWMutex
}

// New creates a new SchemaCache
func New(db *sql.DB, dbName string) *SchemaCache {
	return &SchemaCache{
		db:     db,
		dbName: dbName,
		cache:  make(map[string]*TableSchema),
	}
}

// GetTableSchema returns full schema for a table (lazy loaded)
func (s *SchemaCache) GetTableSchema(table string) (*TableSchema, error) {
	// Check cache first (read lock)
	s.mu.RLock()
	if schema, ok := s.cache[table]; ok {
		s.mu.RUnlock()
		return schema, nil
	}
	s.mu.RUnlock()

	// Query and cache (write lock)
	schema, err := s.queryTableSchema(table)
	if err != nil {
		return nil, err
	}

	s.mu.Lock()
	s.cache[table] = schema
	s.mu.Unlock()

	return schema, nil
}

func (s *SchemaCache) queryTableSchema(table string) (*TableSchema, error) {
	schema := &TableSchema{
		Name:    table,
		Columns: make(map[string]*ColumnInfo),
	}

	// Query all columns with their types
	colQuery := `
		SELECT
			COLUMN_NAME,
			DATA_TYPE,
			IS_NULLABLE
		FROM information_schema.COLUMNS
		WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
		ORDER BY ORDINAL_POSITION
	`
	rows, err := s.db.Query(colQuery, s.dbName, table)
	if err != nil {
		return nil, fmt.Errorf("failed to query columns: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var col ColumnInfo
		var nullable string
		if err := rows.Scan(&col.Name, &col.DataType, &nullable); err != nil {
			return nil, fmt.Errorf("failed to scan column: %w", err)
		}
		col.IsNullable = nullable == "YES"
		schema.Columns[col.Name] = &col
	}

	if len(schema.Columns) == 0 {
		return nil, fmt.Errorf("table %s not found or has no columns", table)
	}

	// Query primary keys
	pkQuery := `
		SELECT COLUMN_NAME
		FROM information_schema.KEY_COLUMN_USAGE
		WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND CONSTRAINT_NAME = 'PRIMARY'
		ORDER BY ORDINAL_POSITION
	`
	pkRows, err := s.db.Query(pkQuery, s.dbName, table)
	if err != nil {
		return nil, fmt.Errorf("failed to query primary keys: %w", err)
	}
	defer pkRows.Close()

	for pkRows.Next() {
		var pkCol string
		if err := pkRows.Scan(&pkCol); err != nil {
			return nil, fmt.Errorf("failed to scan pk: %w", err)
		}
		schema.PrimaryKeys = append(schema.PrimaryKeys, pkCol)
		if col, ok := schema.Columns[pkCol]; ok {
			col.IsPrimary = true
		}
	}

	return schema, nil
}

// GetPrimaryKeys returns primary key columns (backward compatible)
func (s *SchemaCache) GetPrimaryKeys(table string) ([]string, error) {
	schema, err := s.GetTableSchema(table)
	if err != nil {
		return nil, err
	}
	if len(schema.PrimaryKeys) == 0 {
		return nil, fmt.Errorf("no primary key found for table %s", table)
	}
	return schema.PrimaryKeys, nil
}

// IsPrimaryKey checks if a column is part of the primary key
func (s *SchemaCache) IsPrimaryKey(table, column string) bool {
	schema, err := s.GetTableSchema(table)
	if err != nil {
		return false
	}
	for _, pk := range schema.PrimaryKeys {
		if pk == column {
			return true
		}
	}
	return false
}

// GetColumnType returns the data type for a specific column
func (s *SchemaCache) GetColumnType(table, column string) (string, error) {
	schema, err := s.GetTableSchema(table)
	if err != nil {
		return "", err
	}
	if col, ok := schema.Columns[column]; ok {
		return col.DataType, nil
	}
	return "", fmt.Errorf("column %s not found in table %s", column, table)
}

// GetColumnInfo returns full metadata for a specific column
func (s *SchemaCache) GetColumnInfo(table, column string) (*ColumnInfo, error) {
	schema, err := s.GetTableSchema(table)
	if err != nil {
		return nil, err
	}
	if col, ok := schema.Columns[column]; ok {
		return col, nil
	}
	return nil, fmt.Errorf("column %s not found in table %s", column, table)
}

// ClearCache clears all cached schemas
func (s *SchemaCache) ClearCache() {
	s.mu.Lock()
	s.cache = make(map[string]*TableSchema)
	s.mu.Unlock()
}
