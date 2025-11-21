#!/bin/bash

echo "=== Schema Comparison: Source vs Target ==="
echo ""

# Load environment
set -a
source <(grep -v '^#' ../.env)
set +a

# Count tables in source
echo "Source database tables:"
SOURCE_COUNT=$(mysql -h $SOURCE_DB_HOST -P $SOURCE_DB_PORT \
  -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME \
  -sse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$SOURCE_DB_NAME'")
echo "  Total: $SOURCE_COUNT tables"

# Count tables in target
echo ""
echo "Target database tables:"
TARGET_COUNT=$(mysql -h 127.0.0.1 -P 3307 -u $TARGET_DB_USER \
  -p$TARGET_DB_PASSWORD $TARGET_DB_NAME \
  -sse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$TARGET_DB_NAME'")
echo "  Total: $TARGET_COUNT tables"

# Expected difference
EXCLUDED=3
EXPECTED=$((SOURCE_COUNT - EXCLUDED))
echo ""
echo "Expected target tables: $EXPECTED (source - excluded)"
echo "Actual target tables: $TARGET_COUNT"

if [ "$TARGET_COUNT" -eq "$EXPECTED" ]; then
  echo "✓ Table count matches!"
else
  echo "✗ Table count mismatch!"
fi

# Check for deleted_at in target
echo ""
echo "Checking deleted_at columns in target:"
DELETED_AT_COUNT=$(mysql -h 127.0.0.1 -P 3307 -u $TARGET_DB_USER \
  -p$TARGET_DB_PASSWORD $TARGET_DB_NAME \
  -sse "SELECT COUNT(DISTINCT table_name) FROM information_schema.columns
    WHERE table_schema='$TARGET_DB_NAME' AND column_name='deleted_at'")

echo "  Tables with deleted_at: $DELETED_AT_COUNT"
if [ "$DELETED_AT_COUNT" -eq "$TARGET_COUNT" ]; then
  echo "✓ All tables have deleted_at column!"
else
  echo "✗ Some tables missing deleted_at!"
fi

echo ""
echo "=== Comparison Complete ==="
