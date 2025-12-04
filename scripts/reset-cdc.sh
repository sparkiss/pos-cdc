#!/bin/bash
# Reset CDC pipeline for development
# Usage: ./scripts/reset-cdc.sh [--truncate-target]
#
# WARNING: This is for DEVELOPMENT only. Do not use in production!
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
  # === Use Kafka Connect 3.6+ REST API for proper reset ===

  # 1. Stop the connector (not delete)
  echo -e "${YELLOW}Stopping connector...${NC}"
  curl -s -X PUT "${DEBEZIUM_URL}/connectors/${CONNECTOR_NAME}/stop" > /dev/null
  sleep 2

  # 2. Delete offsets via REST API (Kafka Connect 3.6+ feature)
  echo -e "${YELLOW}Deleting connector offsets (REST API)...${NC}"
  RESPONSE=$(curl -s -X DELETE "${DEBEZIUM_URL}/connectors/${CONNECTOR_NAME}/offsets")
  echo "$RESPONSE" | jq -r '.message // .'

  # 3. Delete schema history topic (required for fresh snapshot)
  echo -e "${YELLOW}Deleting schema history topic...${NC}"
  docker exec redpanda rpk topic delete ${TOPIC_PREFIX}.schema_history 2>/dev/null || true

  # 4. Delete data topics
  echo -e "${YELLOW}Deleting data topics...${NC}"
  TOPICS_TO_DELETE=$(docker exec redpanda rpk topic list | grep "^${TOPIC_PREFIX}\." | grep -v schema_history | awk '{print $1}' | tr '\n' ' ')
  if [ -n "$TOPICS_TO_DELETE" ]; then
    docker exec redpanda rpk topic delete $TOPICS_TO_DELETE 2>/dev/null || true
  fi
  sleep 2

  # 5. Resume connector (will do fresh snapshot)
  echo -e "${YELLOW}Resuming connector...${NC}"
  curl -s -X PUT "${DEBEZIUM_URL}/connectors/${CONNECTOR_NAME}/resume" > /dev/null

else
  # === Connector doesn't exist - create fresh ===

  echo -e "${YELLOW}Connector not found, creating fresh...${NC}"

  # Delete any leftover topics
  echo -e "${YELLOW}Deleting leftover topics...${NC}"
  TOPICS_TO_DELETE=$(docker exec redpanda rpk topic list | grep "^${TOPIC_PREFIX}" | awk '{print $1}' | tr '\n' ' ')
  if [ -n "$TOPICS_TO_DELETE" ]; then
    docker exec redpanda rpk topic delete $TOPICS_TO_DELETE 2>/dev/null || true
  fi
  sleep 2

  # Create connector
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
fi

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

  if [ -z "${TARGET_DB_PASSWORD}" ]; then
    echo -e "${RED}Error: TARGET_DB_PASSWORD not set. Source .env first.${NC}"
    exit 1
  fi

  # Get list of tables and truncate each
  docker exec mysql-target mysql -u"${TARGET_DB_USER:-root}" -p"${TARGET_DB_PASSWORD}" "${TARGET_DB_NAME:-pos}" \
    -e "SET FOREIGN_KEY_CHECKS=0; $(docker exec mysql-target mysql -u"${TARGET_DB_USER:-root}" -p"${TARGET_DB_PASSWORD}" "${TARGET_DB_NAME:-pos}" -N -e "SELECT CONCAT('TRUNCATE TABLE \`', table_name, '\`;') FROM information_schema.tables WHERE table_schema='${TARGET_DB_NAME:-pos}'" | tr '\n' ' ') SET FOREIGN_KEY_CHECKS=1;" 2>/dev/null

  echo -e "${GREEN}Target tables truncated${NC}"
fi

# Wait a bit more for topics to be created
sleep 15

echo -e "${GREEN}=== CDC Reset Complete ===${NC}"
echo ""
echo "Topics created:"
docker exec redpanda rpk topic list | grep "${TOPIC_PREFIX}" || echo "(waiting for snapshot...)"
