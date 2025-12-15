package writer

import "database/sql"

// Writer defines the interface for database writers.
// Both MySQL and PostgreSQL writers implement this interface.
type Writer interface {
	// ExecuteBatch executes multiple queries in a single transaction with retry logic.
	// Handles deadlocks by retrying with exponential backoff.
	ExecuteBatch(queries []Query) error

	// Ping verifies the database connection is alive.
	Ping() error

	// Close closes the database connection.
	Close() error

	// DB returns the underlying *sql.DB for schema operations.
	// Used by SchemaCache to query table metadata.
	DB() *sql.DB
}

// Query represents a single database operation.
// Used by both MySQL and PostgreSQL writers.
type Query struct {
	SQL   string
	Args  []any
	Table string
	Op    string
}
