#!/bin/bash
set -e

echo "=== Deploying CDC Pipeline (Production) ==="

# Build latest image
echo "Building Docker image..."
docker build -t pos-cdc-consumer:latest .

# Start services (uses COMPOSE_FILE from .env)
echo "Starting services..."
cd deployments/docker
docker compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Check service health
echo "Checking service health..."
docker compose ps

# Deploy Debezium connector
echo "Deploying Debezium connector..."
sleep 10
curl -X POST \
    -H "Content-Type: application/json" \
    --data @../../configs/debezium-mysql-connector.json \
    http://localhost:8083/connectors

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Services:"
echo "  - Redpanda Console: http://localhost:8080"
echo "  - Prometheus: http://localhost:9091"
echo "  - Grafana: http://localhost:3000 (admin/admin)"
echo "  - CDC Metrics: http://localhost:9090/metrics"
echo ""
echo "Check logs:"
echo "  docker logs cdc-consumer -f"
echo ""
