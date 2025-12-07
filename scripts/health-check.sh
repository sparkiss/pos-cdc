#!/bin/bash

echo "=== CDC Pipeline Health Check ==="
echo ""

# Check Docker containers (run from deployments/docker directory)
cd ~/src/pos-cdc/deployments/docker
echo "Container Status:"
docker compose ps

echo ""
echo "Service Health:"

# Redpanda
echo -n "  Redpanda: "
if curl -s http://localhost:9092 >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

# Redpanda Console
echo -n "  Redpanda Console: "
if curl -s http://localhost:8080 >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

# Debezium
echo -n "  Debezium: "
if curl -s http://localhost:8083 >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

# CDC Consumer
echo -n "  CDC Consumer: "
if curl -s http://localhost:9090/metrics >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

# Prometheus
echo -n "  Prometheus: "
if curl -s http://localhost:9091 >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

# Grafana
echo -n "  Grafana: "
if curl -s http://localhost:3000 >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

echo ""
echo "Consumer Lag:"
docker exec redpanda-prod rpk group describe cdc-consumer-group

echo ""
echo "=== Health Check Complete ==="
