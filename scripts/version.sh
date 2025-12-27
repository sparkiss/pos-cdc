#!/bin/bash
# Check what version is running
# Usage: ./scripts/version.sh

set -e
cd "$(dirname "$0")/.."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== CDC Consumer Version Info ===${NC}"

# Check .env for configured version
if [ -f deployments/docker/.env ]; then
    echo -e "\n${GREEN}Configured in .env:${NC}"
    grep -E "^IMAGE_TAG=|^# Deployed:|^# Build:" deployments/docker/.env 2>/dev/null || echo "IMAGE_TAG not found in .env"
fi

# Check running container's image
echo -e "\n${GREEN}Running container:${NC}"
docker inspect cdc-consumer --format '{{.Config.Image}}' 2>/dev/null || echo "Container not running"

# Check image digest (unique identifier)
echo -e "\n${GREEN}Image digest:${NC}"
docker inspect cdc-consumer --format '{{.Image}}' 2>/dev/null | cut -c8-19 || echo "N/A"

# Check container start time
echo -e "\n${GREEN}Container started:${NC}"
docker inspect cdc-consumer --format '{{.State.StartedAt}}' 2>/dev/null || echo "N/A"

# Check available tags in registry (optional)
echo -e "\n${GREEN}Recent tags in registry:${NC}"
curl -s "https://ghcr.io/v2/sparkiss/pos-cdc-consumer/tags/list" 2>/dev/null | jq -r '.tags | sort | reverse | .[0:5] | .[]' 2>/dev/null || echo "(requires authentication)"
