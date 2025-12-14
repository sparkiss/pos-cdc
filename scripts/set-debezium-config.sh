#!/bin/bash
set -e

echo "=== Debezium Connector Configuration Setup ==="
echo ""

# Check if example exists
if [ ! -f configs/debezium-mysql-connector.json.example ]; then
    echo "[ERROR]: configs/debezium-mysql-connector.json.example not found"
    exit 1
fi

# Load environment variables
if [ ! -f .env ]; then
    echo "[ERROR]: .env file not found"
    echo "   Please create .env with required variables (see .env.example)"
    exit 1
fi

set -a
source .env
set +a

# Generate unique server_id if not set
if [ -z "$DEBEZIUM_SERVER_ID" ]; then
    DEBEZIUM_SERVER_ID=$(echo $((100000 + RANDOM % 900000)))
    echo "Generated Debezium server_id: $DEBEZIUM_SERVER_ID"
    echo "DEBEZIUM_SERVER_ID=$DEBEZIUM_SERVER_ID" >>.env
else
    echo "Using existing Debezium server_id: $DEBEZIUM_SERVER_ID"
fi

# Create real config from example
echo ""
echo "Creating configs/debezium-mysql-connector.json..."

cp configs/debezium-mysql-connector.json.example \
    configs/debezium-mysql-connector.json

# Replace environment variable placeholders with actual values
sed -i "s/SOURCE_DB_HOST/$SOURCE_DB_HOST/g" \
    configs/debezium-mysql-connector.json

# PORT needs to be an integer (remove quotes around the value)
sed -i "s/\"SOURCE_DB_PORT\"/$SOURCE_DB_PORT/g" \
    configs/debezium-mysql-connector.json

sed -i "s/SOURCE_DB_USER/$SOURCE_DB_USER/g" \
    configs/debezium-mysql-connector.json

sed -i "s/SOURCE_DB_PASSWORD/$SOURCE_DB_PASSWORD/g" \
    configs/debezium-mysql-connector.json

# SERVER_ID needs to be an integer (remove quotes around the value)
sed -i "s/\"DEBEZIUM_SERVER_ID\"/$DEBEZIUM_SERVER_ID/g" \
    configs/debezium-mysql-connector.json

# Set restrictive permissions
chmod 600 configs/debezium-mysql-connector.json

echo "[INFO] Configuration created successfully"
echo ""
echo "Details:"
echo "  - File: configs/debezium-mysql-connector.json"
echo "  - Permissions: 600 (owner read/write only)"
echo "  - Server ID: $DEBEZIUM_SERVER_ID"
echo ""
echo "[WARN]  This file contains credentials - DO NOT commit to git!"
echo "    (Already in .gitignore)"
echo "[INFO] You can run the next"
echo "curl -X POST \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  --data @configs/debezium-mysql-connector.json \\"
echo "  http://localhost:8083/connectors"
