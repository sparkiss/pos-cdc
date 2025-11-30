package schema

import (
	"database/sql"
	"fmt"
	"slices"
	"sync"
)

// SchemaCache caches primary key information to avoid repeated database queries
type SchemaCache struct {
	db     *sql.DB
	dbName string
	cache  map[string][]string // table name -> primary key column(s)
	mu     sync.RWMutex
}

// New creates a new SchemaCache
func New(db *sql.DB, dbName string) *SchemaCache {
	return &SchemaCache{
		db:     db,
		dbName: dbName,
		cache:  make(map[string][]string),
	}
}

// GetPrimaryKeys returns the primary key column(s) for a table
// Results are cached after first lookup
func (s *SchemaCache) GetPrimaryKeys(table string) ([]string, error) {
	// Check cache first (read lock)
	s.mu.RLock()
	if pks, ok := s.cache[table]; ok {
		s.mu.RUnlock()
		return pks, nil
	}
	s.mu.RUnlock()

	// Query information_schema (no lock needed for DB query)
	pks, err := s.queryPrimaryKeys(table)
	if err != nil {
		return nil, err
	}

	// Update cache (write lock)
	s.mu.Lock()
	s.cache[table] = pks
	s.mu.Unlock()

	return pks, nil
}

func (s *SchemaCache) queryPrimaryKeys(table string) ([]string, error) {
	query := `
		SELECT COLUMN_NAME
		FROM information_schema.KEY_COLUMN_USAGE
		WHERE TABLE_SCHEMA = ?
		  AND TABLE_NAME = ?
		  AND CONSTRAINT_NAME = 'PRIMARY'
		ORDER BY ORDINAL_POSITION
	`

	rows, err := s.db.Query(query, s.dbName, table)
	if err != nil {
		return nil, fmt.Errorf("failed to query primary keys: %w", err)
	}
	defer rows.Close()

	var pks []string
	for rows.Next() {
		var col string
		if err := rows.Scan(&col); err != nil {
			return nil, fmt.Errorf("failed to scan column: %w", err)
		}
		pks = append(pks, col)
	}

	if len(pks) == 0 {
		return nil, fmt.Errorf("no primary key found for table %s", table)
	}

	return pks, nil
}

func (s *SchemaCache) IsPrimaryKey(table, column string) bool {
	pks, err := s.GetPrimaryKeys(table)
	if err != nil {
		return false
	}
	return slices.Contains(pks, column)
}

func (s *SchemaCache) ClearCache() {
	s.mu.Lock()
	s.cache = make(map[string][]string)
	s.mu.Unlock()
}
