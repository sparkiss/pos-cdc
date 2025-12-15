#!/bin/bash
# Reset CDC pipeline for development
# Usage: ./scripts/reset-cdc.sh [--truncate-target]
#
# WARNING: This is for DEVELOPMENT only. Do not use in production!
#
# The --truncate-target option respects TARGET_TYPE from .env:
#   - TARGET_TYPE=mysql   -> truncates mysql-target container tables
#   - TARGET_TYPE=postgres -> truncates postgres-target container tables
#
# Uses Kafka Connect 3.6+ REST API for proper offset reset:
# https://debezium.io/documentation/faq/

set -e

# Change to script's parent directory (project root)
cd "$(dirname "$0")/.."

CONNECTOR_NAME="pos-mysql-connector"
CONNECTOR_CONFIG="configs/debezium-mysql-connector.json"
CONSUMER_GROUP="cdc-consumer-group"
TOPIC_PREFIX="pos_mysql"
DEBEZIUM_URL="http://localhost:8083"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== CDC Pipeline Reset ===${NC}"

# Check if Debezium is reachable
if ! curl -s "${DEBEZIUM_URL}/" > /dev/null 2>&1; then
  echo -e "${RED}Error: Cannot reach Debezium at ${DEBEZIUM_URL}${NC}"
  echo "Make sure the Debezium container is running."
  exit 1
fi

# Check if connector exists
CONNECTOR_EXISTS=$(curl -s "${DEBEZIUM_URL}/connectors" | jq -r ". | index(\"${CONNECTOR_NAME}\") != null")

if [ "$CONNECTOR_EXISTS" = "true" ]; then
  # === Delete connector to ensure fresh config is applied ===

  # 1. Delete the connector (this also stops it)
  echo -e "${YELLOW}Deleting connector...${NC}"
  curl -s -X DELETE "${DEBEZIUM_URL}/connectors/${CONNECTOR_NAME}" > /dev/null

  # Wait for connector to be fully removed
  echo -e "${YELLOW}Waiting for connector to be removed...${NC}"
  for i in {1..10}; do
    if ! curl -s "${DEBEZIUM_URL}/connectors/${CONNECTOR_NAME}" | jq -e '.name' > /dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  # 2. Stop Debezium container FIRST (prevents auto-creating topics with wrong policy)
  echo -e "${YELLOW}Stopping Debezium container...${NC}"
  docker stop debezium > /dev/null 2>&1

  # 3. Delete all related topics
  echo -e "${YELLOW}Deleting Kafka Connect internal topics...${NC}"
  docker exec redpanda rpk topic delete debezium_offsets debezium_configs debezium_status 2>/dev/null || true

  echo -e "${YELLOW}Deleting schema history topic...${NC}"
  docker exec redpanda rpk topic delete ${TOPIC_PREFIX}.schema_history 2>/dev/null || true

  echo -e "${YELLOW}Deleting data topics...${NC}"
  TOPICS_TO_DELETE=$(docker exec redpanda rpk topic list | grep "^${TOPIC_PREFIX}" | awk '{print $1}' | tr '\n' ' ')
  if [ -n "$TOPICS_TO_DELETE" ]; then
    docker exec redpanda rpk topic delete $TOPICS_TO_DELETE 2>/dev/null || true
  fi
  sleep 2

  # 4. Recreate internal topics with cleanup.policy=compact BEFORE starting Debezium
  echo -e "${YELLOW}Recreating internal topics with cleanup.policy=compact...${NC}"
  docker exec redpanda rpk topic create debezium_offsets -c cleanup.policy=compact
  docker exec redpanda rpk topic create debezium_configs -c cleanup.policy=compact
  docker exec redpanda rpk topic create debezium_status -c cleanup.policy=compact

  # 5. Start Debezium container
  echo -e "${YELLOW}Starting Debezium container...${NC}"
  docker start debezium > /dev/null 2>&1

  # Wait for Debezium to be ready
  echo -e "${YELLOW}Waiting for Debezium to be ready...${NC}"
  for i in {1..30}; do
    if curl -s "${DEBEZIUM_URL}/" > /dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  echo -e "${YELLOW}Recreating connector with latest config...${NC}"
else
  # Delete any leftover topics
  echo -e "${YELLOW}Deleting leftover topics...${NC}"
  TOPICS_TO_DELETE=$(docker exec redpanda rpk topic list | grep "^${TOPIC_PREFIX}" | awk '{print $1}' | tr '\n' ' ')
  if [ -n "$TOPICS_TO_DELETE" ]; then
    docker exec redpanda rpk topic delete $TOPICS_TO_DELETE 2>/dev/null || true
  fi
  sleep 2
fi

# === Create connector (shared logic for both branches) ===
echo -e "${YELLOW}Creating connector...${NC}"
if [ ! -f "${CONNECTOR_CONFIG}" ]; then
  echo -e "${RED}Error: Config file not found: ${CONNECTOR_CONFIG}${NC}"
  exit 1
fi

# Retry connector creation (worker may not be ready)
for attempt in {1..10}; do
  RESPONSE=$(curl -sS -X POST "${DEBEZIUM_URL}/connectors" \
    -H "Content-Type: application/json" \
    -d @"${CONNECTOR_CONFIG}" 2>/dev/null)

  if echo "$RESPONSE" | jq -e '.name' > /dev/null 2>&1; then
    echo -e "${GREEN}Connector created: $(echo "$RESPONSE" | jq -r '.name')${NC}"
    break
  fi

  if [ $attempt -eq 10 ]; then
    echo -e "${RED}Failed to create connector after 10 attempts${NC}"
    echo "$RESPONSE"
    exit 1
  fi

  echo "Waiting for worker to be ready (attempt $attempt/10)..."
  sleep 3
done

# Wait for connector to start running
echo -e "${YELLOW}Waiting for snapshot to start...${NC}"
sleep 10

# Check connector status
for i in {1..30}; do
  STATUS=$(curl -s "${DEBEZIUM_URL}/connectors/${CONNECTOR_NAME}/status" | jq -r '.tasks[0].state // "UNKNOWN"')
  if [ "$STATUS" = "RUNNING" ]; then
    echo -e "${GREEN}Connector is RUNNING${NC}"
    break
  elif [ "$STATUS" = "FAILED" ]; then
    echo -e "${RED}Connector FAILED${NC}"
    curl -s "${DEBEZIUM_URL}/connectors/${CONNECTOR_NAME}/status" | jq -r '.tasks[0].trace' | head -5
    exit 1
  fi
  sleep 1
done

# Reset consumer offset (if consumer group exists)
echo -e "${YELLOW}Resetting consumer offset...${NC}"
docker exec redpanda rpk group seek "${CONSUMER_GROUP}" --to start 2>/dev/null || echo "Consumer group not found (will be created on first run)"

# Optional: Truncate target tables
if [ "$1" = "--truncate-target" ]; then
  echo -e "${YELLOW}Truncating target tables...${NC}"
  # Source .env for credentials
  if [ -f .env ]; then
    set -a
    source .env
    set +a
  fi

  # Determine target type (default to mysql for backwards compatibility)
  TARGET_TYPE="${TARGET_TYPE:-mysql}"

  if [ "$TARGET_TYPE" = "postgres" ]; then
    # PostgreSQL target
    if [ -z "${TARGET_PG_PASSWORD}" ]; then
      echo -e "${RED}Error: TARGET_PG_PASSWORD not set. Source .env first.${NC}"
      exit 1
    fi

    # Truncate all tables in PostgreSQL
    docker exec postgres-target psql -U "${TARGET_PG_USER:-cdc_writer}" -d "${TARGET_PG_DATABASE:-pos_replica}" -c "
      DO \$\$
      DECLARE
        r RECORD;
      BEGIN
        FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
          EXECUTE 'TRUNCATE TABLE \"' || r.tablename || '\" CASCADE';
        END LOOP;
      END \$\$;
    " 2>/dev/null

    echo -e "${GREEN}PostgreSQL target tables truncated${NC}"
  else
    # MySQL target (default)
    if [ -z "${TARGET_DB_PASSWORD}" ]; then
      echo -e "${RED}Error: TARGET_DB_PASSWORD not set. Source .env first.${NC}"
      exit 1
    fi

    # Get list of tables and truncate each
    docker exec mysql-target mysql -u"${TARGET_DB_USER:-root}" -p"${TARGET_DB_PASSWORD}" "${TARGET_DB_NAME:-pos}" \
      -e "SET FOREIGN_KEY_CHECKS=0; $(docker exec mysql-target mysql -u"${TARGET_DB_USER:-root}" -p"${TARGET_DB_PASSWORD}" "${TARGET_DB_NAME:-pos}" -N -e "SELECT CONCAT('TRUNCATE TABLE \`', table_name, '\`;') FROM information_schema.tables WHERE table_schema='${TARGET_DB_NAME:-pos}'" | tr '\n' ' ') SET FOREIGN_KEY_CHECKS=1;" 2>/dev/null

    echo -e "${GREEN}MySQL target tables truncated${NC}"
  fi
fi

# Wait a bit more for topics to be created
sleep 15

echo -e "${GREEN}=== CDC Reset Complete ===${NC}"
echo ""
echo "Topics created:"
docker exec redpanda rpk topic list | grep "${TOPIC_PREFIX}" || echo "(waiting for snapshot...)"
