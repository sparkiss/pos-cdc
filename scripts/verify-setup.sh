#!/bin/bash

echo "== ENV Setup Verification =="
echo ""

# Docker
echo -n "Docker: "
if command -v docker &>/dev/null; then
  echo "[INFO] $(docker --version)"
else
  echo "[ERROR] Not installed"
fi

# Docker Compose
echo -n "Docker Compose: "
if command -v docker compose &>/dev/null; then
  echo "[INFO] $(docker compose version)"
else
  echo "[ERROR] Not installed"
fi

# Go
echo -n "Go: "
if command -v go &>/dev/null; then
  echo "[INFO] $(go version)"
else
  echo "[ERROR] Not installed"
fi

# Git
echo -n "Git: "
if command -v git &>/dev/null; then
  echo "[INFO] $(git --version)"
else
  echo "[ERROR] Not installed"
fi

# jq
echo -n "jq: "
if command -v jq &>/dev/null; then
  echo "[INFO] $(jq --version)"
else
  echo "[ERROR] Not installed"
fi

# Docker network
echo -n "Docker network (cdc-network): "
if docker network ls | grep -q cdc-network; then
  echo "[INFO] Created"
else
  echo "[ERROR] Not created"
fi

# Check .env file
echo -n ".env file: "
if [ -f ".env" ]; then
  echo "[INFO] Exists"
else
  echo "[ERROR] Not created"
fi

echo ""
echo "=== Source Database Connectivity ==="
echo "Testing connection to 192.168.0.74:3306..."

# Load .env if exists
if [ -f ".env" ]; then
  export $(cat .env | grep -v '^#' | sed 's/#.*$//' | xargs)
fi

if command -v mysql &>/dev/null && [ ! -z "$SOURCE_DB_PASSWORD" ]; then
  if mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD --skip-ssl -e "SELECT 1" &>/dev/null; then
    echo "[INFO] Source database accessible"
  else
    echo "[ERROR] Cannot connect to source database"
  fi
else
  echo "[ERROR] MySQL client not installed or .env not configured"
fi

echo ""
echo "=== Setup Complete ==="
