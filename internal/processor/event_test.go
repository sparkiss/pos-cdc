package processor

import (
	"os"
	"strings"
	"testing"
	"time"

	"github.com/sparkiss/pos-cdc/internal/config"
	"github.com/sparkiss/pos-cdc/internal/models"
	"github.com/sparkiss/pos-cdc/internal/schema"
	"github.com/sparkiss/pos-cdc/pkg/logger"
)

// TestMain sets up the logger for all tests in this package
func TestMain(m *testing.M) {
	// Initialize logger to avoid nil pointer
	_ = logger.Init("error", "text")
	os.Exit(m.Run())
}

// Helper to create a test processor
func newTestProcessor() *Processor {
	return &Processor{
		converter:  schema.NewConverter(time.UTC, time.UTC, config.TargetMySQL),
		sqlBuilder: NewMySQLBuilder(),
		targetType: config.TargetMySQL,
	}
}

// createTestSchema creates a typical orders table schema
func createOrdersSchema() *schema.TableSchema {
	return &schema.TableSchema{
		Name: "orders",
		Columns: map[string]*schema.ColumnInfo{
			"id":          {Name: "id", DataType: "bigint", IsPrimary: true},
			"customer_id": {Name: "customer_id", DataType: "bigint"},
			"total":       {Name: "total", DataType: "decimal"},
			"status":      {Name: "status", DataType: "varchar"},
			"created_at":  {Name: "created_at", DataType: "datetime"},
		},
		PrimaryKeys: []string{"id"},
	}
}

// createUsersSchema creates a users table schema with composite PK
func createUsersSchema() *schema.TableSchema {
	return &schema.TableSchema{
		Name: "user_roles",
		Columns: map[string]*schema.ColumnInfo{
			"user_id": {Name: "user_id", DataType: "bigint", IsPrimary: true},
			"role_id": {Name: "role_id", DataType: "bigint", IsPrimary: true},
			"granted": {Name: "granted", DataType: "datetime"},
		},
		PrimaryKeys: []string{"user_id", "role_id"},
	}
}

func TestMySQLBuilder_BuildInsert(t *testing.T) {
	builder := NewMySQLBuilder()
	tableSchema := createOrdersSchema()

	payload := map[string]any{
		"id":          int64(1),
		"customer_id": int64(100),
		"total":       "99.99",
		"status":      "pending",
	}

	sql, args, err := builder.BuildInsert("orders", payload, tableSchema)
	if err != nil {
		t.Fatalf("BuildInsert() error = %v", err)
	}

	// Check SQL structure
	if !strings.HasPrefix(sql, "INSERT INTO `orders`") {
		t.Errorf("SQL should start with INSERT INTO `orders`, got: %s", sql)
	}
	if !strings.Contains(sql, "ON DUPLICATE KEY UPDATE") {
		t.Error("SQL should contain ON DUPLICATE KEY UPDATE")
	}
	if !strings.Contains(sql, "`deleted_at`") {
		t.Error("SQL should include deleted_at column")
	}
	if !strings.Contains(sql, "`deleted_at` = NULL") {
		t.Error("SQL should set deleted_at = NULL in update clause")
	}

	// Check args count (payload fields + deleted_at)
	if len(args) != 5 { // 4 payload fields + 1 deleted_at
		t.Errorf("args count = %d, want 5", len(args))
	}

	// Last arg should be nil (deleted_at)
	if args[len(args)-1] != nil {
		t.Errorf("last arg should be nil for deleted_at, got %v", args[len(args)-1])
	}
}

func TestMySQLBuilder_BuildInsert_SkipsMetaFields(t *testing.T) {
	builder := NewMySQLBuilder()
	tableSchema := createOrdersSchema()

	payload := map[string]any{
		"id":             int64(1),
		"customer_id":    int64(100),
		"__op":           "c",
		"__ts_ms":        int64(1735689600000),
		"__source_table": "orders",
	}

	sql, args, err := builder.BuildInsert("orders", payload, tableSchema)
	if err != nil {
		t.Fatalf("BuildInsert() error = %v", err)
	}

	// Meta fields should not be in SQL
	if strings.Contains(sql, "__op") {
		t.Error("SQL should not contain __op meta field")
	}
	if strings.Contains(sql, "__ts_ms") {
		t.Error("SQL should not contain __ts_ms meta field")
	}

	// Only 2 real fields + deleted_at = 3 args
	if len(args) != 3 {
		t.Errorf("args count = %d, want 3 (excluding meta fields)", len(args))
	}
}

func TestMySQLBuilder_BuildUpdate(t *testing.T) {
	builder := NewMySQLBuilder()
	tableSchema := createOrdersSchema()

	payload := map[string]any{
		"id":     int64(1),
		"status": "completed",
		"total":  "149.99",
	}

	sql, args, err := builder.BuildUpdate("orders", payload, tableSchema)
	if err != nil {
		t.Fatalf("BuildUpdate() error = %v", err)
	}

	// Check SQL structure
	if !strings.HasPrefix(sql, "UPDATE `orders` SET") {
		t.Errorf("SQL should start with UPDATE `orders` SET, got: %s", sql)
	}
	if !strings.Contains(sql, "WHERE `id` = ?") {
		t.Errorf("SQL should contain WHERE `id` = ?, got: %s", sql)
	}

	// Check that PK is not in SET clause
	if strings.Contains(sql, "SET `id`") {
		t.Error("SQL should not SET the primary key")
	}

	// Args: SET values + WHERE value
	// status, total (2 SET) + id (1 WHERE) = 3
	if len(args) != 3 {
		t.Errorf("args count = %d, want 3", len(args))
	}
}

func TestMySQLBuilder_BuildUpdate_CompositePK(t *testing.T) {
	builder := NewMySQLBuilder()
	tableSchema := createUsersSchema()

	payload := map[string]any{
		"user_id": int64(1),
		"role_id": int64(2),
		"granted": "2025-01-01 12:00:00",
	}

	sql, args, err := builder.BuildUpdate("user_roles", payload, tableSchema)
	if err != nil {
		t.Fatalf("BuildUpdate() error = %v", err)
	}

	// Should have both PKs in WHERE
	if !strings.Contains(sql, "`user_id` = ?") {
		t.Error("SQL should contain user_id in WHERE")
	}
	if !strings.Contains(sql, "`role_id` = ?") {
		t.Error("SQL should contain role_id in WHERE")
	}
	if !strings.Contains(sql, "AND") {
		t.Error("SQL WHERE should use AND for composite PK")
	}

	// Args: 1 SET (granted) + 2 WHERE (user_id, role_id) = 3
	if len(args) != 3 {
		t.Errorf("args count = %d, want 3", len(args))
	}
}

func TestMySQLBuilder_BuildUpdate_NoPrimaryKey(t *testing.T) {
	builder := NewMySQLBuilder()
	tableSchema := &schema.TableSchema{
		Name: "no_pk_table",
		Columns: map[string]*schema.ColumnInfo{
			"data": {Name: "data", DataType: "varchar"},
		},
		PrimaryKeys: []string{}, // No primary key
	}

	payload := map[string]any{
		"data": "test",
	}

	_, _, err := builder.BuildUpdate("no_pk_table", payload, tableSchema)
	if err == nil {
		t.Error("BuildUpdate() should return error for table without primary key")
	}
}

func TestMySQLBuilder_BuildUpdate_OnlyPKColumns(t *testing.T) {
	builder := NewMySQLBuilder()
	tableSchema := createOrdersSchema()

	// Payload only contains PK - no non-PK columns to update
	payload := map[string]any{
		"id": int64(1),
	}

	_, _, err := builder.BuildUpdate("orders", payload, tableSchema)
	if err == nil {
		t.Error("BuildUpdate() should return error when payload has only PK columns")
	}
	if !strings.Contains(err.Error(), "no columns to update") {
		t.Errorf("error message should mention 'no columns to update', got: %v", err)
	}
}

func TestPostgresBuilder_BuildUpdate_OnlyPKColumns(t *testing.T) {
	builder := NewPostgresBuilder()
	tableSchema := createOrdersSchema()

	// Payload only contains PK - no non-PK columns to update
	payload := map[string]any{
		"id": int64(1),
	}

	_, _, err := builder.BuildUpdate("orders", payload, tableSchema)
	if err == nil {
		t.Error("BuildUpdate() should return error when payload has only PK columns")
	}
	if !strings.Contains(err.Error(), "no columns to update") {
		t.Errorf("error message should mention 'no columns to update', got: %v", err)
	}
}

func TestMySQLBuilder_BuildDelete(t *testing.T) {
	builder := NewMySQLBuilder()
	tableSchema := createOrdersSchema()

	payload := map[string]any{
		"id": int64(1),
	}

	sql, args, err := builder.BuildDelete("orders", payload, tableSchema)
	if err != nil {
		t.Fatalf("BuildDelete() error = %v", err)
	}

	// Check SQL structure - should be UPDATE for soft delete
	if !strings.HasPrefix(sql, "UPDATE `orders` SET `deleted_at` = ?") {
		t.Errorf("SQL should be UPDATE for soft delete, got: %s", sql)
	}
	if !strings.Contains(sql, "WHERE `id` = ?") {
		t.Errorf("SQL should contain WHERE `id` = ?, got: %s", sql)
	}

	// Args: 1 (deleted_at timestamp) + 1 (WHERE id) = 2
	if len(args) != 2 {
		t.Errorf("args count = %d, want 2", len(args))
	}

	// First arg should be a time.Time
	if _, ok := args[0].(time.Time); !ok {
		t.Errorf("first arg should be time.Time, got %T", args[0])
	}
}

func TestMySQLBuilder_BuildDelete_CompositePK(t *testing.T) {
	builder := NewMySQLBuilder()
	tableSchema := createUsersSchema()

	payload := map[string]any{
		"user_id": int64(1),
		"role_id": int64(2),
	}

	sql, args, err := builder.BuildDelete("user_roles", payload, tableSchema)
	if err != nil {
		t.Fatalf("BuildDelete() error = %v", err)
	}

	// Should have both PKs in WHERE
	if !strings.Contains(sql, "`user_id` = ?") {
		t.Error("SQL should contain user_id in WHERE")
	}
	if !strings.Contains(sql, "`role_id` = ?") {
		t.Error("SQL should contain role_id in WHERE")
	}

	// Args: 1 (deleted_at) + 2 (WHERE PKs) = 3
	if len(args) != 3 {
		t.Errorf("args count = %d, want 3", len(args))
	}
}

func TestMySQLBuilder_BuildDelete_MissingPK(t *testing.T) {
	builder := NewMySQLBuilder()
	tableSchema := createUsersSchema()

	// Missing role_id
	payload := map[string]any{
		"user_id": int64(1),
	}

	_, _, err := builder.BuildDelete("user_roles", payload, tableSchema)
	if err == nil {
		t.Error("BuildDelete() should return error when PK values are missing")
	}
}

func TestProcessor_ConvertPayload(t *testing.T) {
	p := newTestProcessor()
	tableSchema := createOrdersSchema()

	payload := map[string]any{
		"id":          int64(1),
		"created_at":  "2025-01-01T00:00:00Z", // ISO8601 string (avoids local TZ issues)
		"__op":        "c",                    // meta field
		"__source_db": "pos",                  // meta field
	}

	converted := p.convertPayload(payload, tableSchema)

	// Meta fields should be passed through unchanged
	if converted["__op"] != "c" {
		t.Errorf("__op should be passed through, got %v", converted["__op"])
	}
	if converted["__source_db"] != "pos" {
		t.Errorf("__source_db should be passed through, got %v", converted["__source_db"])
	}

	// created_at should be converted to MySQL format string
	createdAt, ok := converted["created_at"].(string)
	if !ok {
		t.Fatalf("created_at should be string, got %T", converted["created_at"])
	}
	// The converter parses ISO8601 "Z" as UTC and converts to target UTC
	if createdAt != "2025-01-01 00:00:00" {
		t.Errorf("created_at = %v, want 2025-01-01 00:00:00", createdAt)
	}

	// id should be passed through (bigint)
	if converted["id"] != int64(1) {
		t.Errorf("id should be passed through, got %v", converted["id"])
	}
}

func TestProcessor_ConvertPayload_UnknownColumn(t *testing.T) {
	p := newTestProcessor()
	tableSchema := createOrdersSchema()

	// Column not in schema
	payload := map[string]any{
		"unknown_column": "value",
	}

	converted := p.convertPayload(payload, tableSchema)

	// Unknown columns should be passed through
	if converted["unknown_column"] != "value" {
		t.Errorf("unknown column should be passed through, got %v", converted["unknown_column"])
	}
}

func TestCDCEvent_GetOperation_Integration(t *testing.T) {
	// Test that models.CDCEvent.GetOperation() works correctly with processor
	tests := []struct {
		op       string
		expected models.Operation
	}{
		{"c", models.OperationInsert},
		{"r", models.OperationInsert},
		{"u", models.OperationUpdate},
		{"d", models.OperationDelete},
	}

	for _, tt := range tests {
		t.Run(tt.op, func(t *testing.T) {
			event := &models.CDCEvent{Operation: tt.op}
			if got := event.GetOperation(); got != tt.expected {
				t.Errorf("GetOperation() = %v, want %v", got, tt.expected)
			}
		})
	}
}

// Test PostgreSQL builder
func TestPostgresBuilder_BuildInsert(t *testing.T) {
	builder := NewPostgresBuilder()
	tableSchema := createOrdersSchema()

	payload := map[string]any{
		"id":          int64(1),
		"customer_id": int64(100),
		"total":       "99.99",
		"status":      "pending",
	}

	sql, args, err := builder.BuildInsert("orders", payload, tableSchema)
	if err != nil {
		t.Fatalf("BuildInsert() error = %v", err)
	}

	// Check PostgreSQL-specific syntax (lowercase, unquoted identifiers)
	if !strings.HasPrefix(sql, "INSERT INTO orders") {
		t.Errorf("SQL should start with INSERT INTO orders (lowercase, unquoted), got: %s", sql)
	}
	if !strings.Contains(sql, "ON CONFLICT") {
		t.Error("SQL should contain ON CONFLICT")
	}
	if !strings.Contains(sql, "DO UPDATE SET") {
		t.Error("SQL should contain DO UPDATE SET")
	}
	if !strings.Contains(sql, "$1") {
		t.Error("SQL should use $1 placeholders")
	}
	if !strings.Contains(sql, "deleted_at") {
		t.Error("SQL should include deleted_at column")
	}

	// Check args count (payload fields + deleted_at)
	if len(args) != 5 { // 4 payload fields + 1 deleted_at
		t.Errorf("args count = %d, want 5", len(args))
	}
}

func TestPostgresBuilder_BuildDelete(t *testing.T) {
	builder := NewPostgresBuilder()
	tableSchema := createOrdersSchema()

	payload := map[string]any{
		"id": int64(1),
	}

	sql, args, err := builder.BuildDelete("orders", payload, tableSchema)
	if err != nil {
		t.Fatalf("BuildDelete() error = %v", err)
	}

	// Check PostgreSQL-specific syntax (lowercase, unquoted identifiers)
	if !strings.HasPrefix(sql, "UPDATE orders SET deleted_at = $1") {
		t.Errorf("SQL should be UPDATE with $1 for soft delete (lowercase, unquoted), got: %s", sql)
	}
	if !strings.Contains(sql, "WHERE id = $2") {
		t.Errorf("SQL should contain WHERE id = $2, got: %s", sql)
	}

	// Args: 1 (deleted_at timestamp) + 1 (WHERE id) = 2
	if len(args) != 2 {
		t.Errorf("args count = %d, want 2", len(args))
	}
}
