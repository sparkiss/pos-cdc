package writer

import (
	"database/sql"
	"fmt"
	_ "github.com/go-sql-driver/mysql"
	"log"
	"time"
)

type MySQLWriter struct {
	db         *sql.DB
	maxRetries int
	backoffMS  int
}

// FIXME: separate to Config model later
type Config struct {
	Host       string
	Port       int
	User       string
	Password   string
	Database   string
	MaxRetries int
	BackoffMS  int
}

func New(cfg Config) (*MySQLWriter, error) {

	//format: ser:password@tcp(host:port)/database?options
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?parseTime=true&loc=UTC",
		cfg.User,
		cfg.Password,
		cfg.Host,
		cfg.Port,
		cfg.Database,
	)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// TODO: Make these configurable
	db.SetMaxOpenConns(25)                 // Max open connections
	db.SetMaxIdleConns(5)                  // Max idle connections
	db.SetConnMaxLifetime(5 * time.Minute) // Max connection age

	// Test connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	log.Printf("Connected to MySQL: %s:%d/%s", cfg.Host, cfg.Port, cfg.Database)

	return &MySQLWriter{
		db:         db,
		maxRetries: cfg.MaxRetries,
		backoffMS:  cfg.BackoffMS,
	}, nil
}

func (w *MySQLWriter) Execute(sqlStr string, args []any) error {
	var err error
	for attempt := 0; attempt <= w.maxRetries; attempt++ {
		if attempt > 0 {
			backoff := time.Duration(w.backoffMS*(1<<uint(attempt-1))) * time.Millisecond
			log.Printf("Retry %d/%d after %v", attempt, w.maxRetries, backoff)
			time.Sleep(backoff)
		}

		_, err = w.db.Exec(sqlStr, args...)
		if err == nil {
			return nil // Success!
		}

		log.Printf("Query faield (attempt %d): %v", attempt, err)
		log.Printf("SQL: %s", sqlStr)
		log.Printf("Args: %v", args)
	}

	return fmt.Errorf("failed after %d retries: %w", w.maxRetries, err)
}

func (w *MySQLWriter) Close() error {
	return w.db.Close()
}

func (w *MySQLWriter) Ping() error {
	return w.db.Ping()
}
