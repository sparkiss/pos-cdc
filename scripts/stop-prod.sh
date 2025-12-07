#!/bin/bash

echo "Stopping CDC Pipeline..."

cd ~/src/pos-cdc/deployments/docker
docker compose down

echo "CDC Pipeline stopped"
