#!/bin/bash

echo "=== Debezium Validation ==="

# Check connector exists
echo -n "Connector registered: "
if curl -s http://localhost:8083/connectors | grep -q "pos-mysql-connector"; then
    echo "✅"
else
    echo "❌"
    exit 1
fi

# Check connector status
echo -n "Connector running: "
STATUS=$(curl -s http://localhost:8083/connectors/pos-mysql-connector/status | jq -r '.connector.state')
if [ "$STATUS" == "RUNNING" ]; then
    echo "✅"
else
    echo "❌ (Status: $STATUS)"
fi

# Check task status
echo -n "Task running: "
TASK_STATUS=$(curl -s http://localhost:8083/connectors/pos-mysql-connector/status | jq -r '.tasks[0].state')
if [ "$TASK_STATUS" == "RUNNING" ]; then
    echo "✅"
else
    echo "❌ (Status: $TASK_STATUS)"
fi

# Count topics
echo -n "Topics created: "
TOPIC_COUNT=$(docker exec -it redpanda rpk topic list 2>/dev/null | grep "pos_mysql" | wc -l)
echo "$TOPIC_COUNT"

echo "✅ Found $TOPIC_COUNT topics"

echo ""
echo "=== Validation Complete ==="
