#!/bin/bash
# scripts/jenkins-deploy.sh
# Called by Jenkins after .env is created on the server
# Expects: GHCR_USER, GHCR_TOKEN, IMAGE_TAG environment variables
set -ex

cd /opt/pos-cdc

# Pull latest code
git pull origin main

# Create symlink for scripts that expect .env at project root
ln -sf deployments/docker/.env .env

# Generate Debezium connector config from .env
./scripts/set-debezium-config.sh

cd deployments/docker

# Login to GitHub Container Registry
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin

# Pull latest image
docker pull "ghcr.io/sparkiss/pos-cdc-consumer:${IMAGE_TAG:-latest}"

# Restart CDC consumer only
docker compose up -d --no-deps cdc-consumer

# Wait for container to start
sleep 30

# Verify deployment
docker compose ps

# Health check with log capture on failure
if ! curl -f http://localhost:8081/health; then
    echo ""
    echo "=== HEALTH CHECK FAILED ==="
    echo "Container logs (last 100 lines):"
    echo "================================"
    docker logs cdc-consumer --tail 100 2>&1 || true
    echo "================================"
    exit 1
fi

echo "Deployment successful!"
