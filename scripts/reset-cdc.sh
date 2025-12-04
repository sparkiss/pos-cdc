#!/bin/bash
# Reset CDC pipeline for development
# Usage: ./scripts/reset-cdc.sh [--truncate-target]
#
# WARNING: This is for DEVELOPMENT only. Do not use in production!

set -e

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

# 1. Delete connector
echo -e "${YELLOW}Deleting connector...${NC}"
curl -s -X DELETE "${DEBEZIUM_URL}/connectors/${CONNECTOR_NAME}" || true
sleep 2

# 2. Delete data topics and schema_history
echo -e "${YELLOW}Deleting data topics...${NC}"
TOPICS_TO_DELETE=$(docker exec redpanda rpk topic list | grep "^${TOPIC_PREFIX}" | awk '{print $1}' | tr '\n' ' ')
if [ -n "$TOPICS_TO_DELETE" ]; then
  docker exec redpanda rpk topic delete $TOPICS_TO_DELETE 2>/dev/null || true
fi
sleep 2

# 2.5 Delete Debezium internal topics to force fresh snapshot
echo -e "${YELLOW}Deleting Debezium internal topics...${NC}"
docker exec redpanda rpk topic delete debezium_offsets debezium_configs debezium_status 2>/dev/null || true
sleep 2

# 3. Recreate connector
echo -e "${YELLOW}Creating connector...${NC}"
if [ ! -f "${CONNECTOR_CONFIG}" ]; then
  echo -e "${RED}Error: Config file not found: ${CONNECTOR_CONFIG}${NC}"
  exit 1
fi
curl -s -X POST "${DEBEZIUM_URL}/connectors" \
  -H "Content-Type: application/json" \
  -d @"${CONNECTOR_CONFIG}" | jq .

# 5. Wait for connector to start
echo -e "${YELLOW}Waiting for connector to start...${NC}"
sleep 10

# 6. Check connector status
STATUS=$(curl -s "${DEBEZIUM_URL}/connectors/${CONNECTOR_NAME}/status" | jq -r '.tasks[0].state // "UNKNOWN"')
if [ "$STATUS" = "RUNNING" ]; then
  echo -e "${GREEN}Connector is RUNNING${NC}"
else
  echo -e "${RED}Connector status: ${STATUS}${NC}"
  echo "Check Debezium logs: docker logs debezium"
  exit 1
fi

# 7. Reset consumer offset (if consumer group exists)
echo -e "${YELLOW}Resetting consumer offset...${NC}"
docker exec redpanda rpk group seek "${CONSUMER_GROUP}" --to start 2>/dev/null || echo "Consumer group not found (will be created on first run)"

# 8. Optional: Truncate target tables
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

echo -e "${GREEN}=== CDC Reset Complete ===${NC}"
echo ""
echo "Topics created:"
docker exec redpanda rpk topic list | grep "${TOPIC_PREFIX}" || echo "(waiting for snapshot...)"
