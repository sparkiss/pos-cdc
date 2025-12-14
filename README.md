# POS CDC Consumer

A Change Data Capture (CDC) pipeline that replicates data from a MySQL 5.7 production database to a MySQL 8 target database using Debezium and Redpanda (Kafka-compatible).

## Problem It Solves

- **Real-time data replication** from legacy MySQL 5.7 to modern MySQL 8
- **Zero-downtime migration** - source database continues operating normally
- **Selective replication** - exclude unnecessary tables (logs, locks, etc.)
- **Soft deletes on target** - preserves data history even when source does hard deletes
- **Timezone handling** - correctly converts timestamps between different timezones

## Architecture

```
┌─────────────────┐     ┌───────────┐     ┌───────────┐     ┌─────────────────┐
│  MySQL 5.7      │────▶│ Debezium  │────▶│ Redpanda  │────▶│  CDC Consumer   │
│  (Source)       │     │ Connector │     │ (Kafka)   │     │  (Go App)       │
└─────────────────┘     └───────────┘     └───────────┘     └────────┬────────┘
                                                                     │
                                                                     ▼
                                                            ┌─────────────────┐
                                                            │    MySQL 8      │
                                                            │   (Target)      │
                                                            └─────────────────┘
```

## Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| Source DB | MySQL 5.7 | Production database |
| Target DB | MySQL 8 | Replica database |
| CDC Capture | Debezium | Reads MySQL binlog |
| Message Broker | Redpanda | Kafka-compatible streaming |
| Consumer | Go | Processes events, writes to target |
| Monitoring | Prometheus + Grafana | Metrics and visualization |
| CI/CD | Jenkins | Build, test, deploy |

## Prerequisites

- Docker and Docker Compose
- Go 1.25+ (for local development)
- Access to source MySQL with binlog enabled
- Jenkins (for CI/CD)

## Quick Start (Development)

### 1. Clone and Configure

```bash
git clone https://github.com/sparkiss/pos-cdc.git
cd pos-cdc

# Copy and edit environment file
cp .env.example deployments/docker/.env
nano deployments/docker/.env
```

### 2. Create Docker Network

```bash
docker network create cdc-network
```

### 3. Start Services

```bash
cd deployments/docker

# Development (includes local MySQL target)
COMPOSE_FILE=docker-compose.yml:docker-compose.dev.yml docker compose up -d

# Or set in .env:
# COMPOSE_FILE=docker-compose.yml:docker-compose.dev.yml
docker compose up -d
```

### 4. Configure Debezium Connector

```bash
cd /path/to/pos-cdc

# Generate connector config from .env
./scripts/set-debezium-config.sh

# Register connector with Debezium
curl -X POST \
  -H "Content-Type: application/json" \
  --data @configs/debezium-mysql-connector.json \
  http://localhost:8083/connectors
```

### 5. Run Consumer (Local Development)

```bash
# Load environment
set -a && source deployments/docker/.env && set +a

# Run
go run cmd/cdc-consumer/main.go
```

## Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SOURCE_DB_HOST` | Source MySQL host | `192.168.0.74` |
| `SOURCE_DB_PORT` | Source MySQL port | `3306` |
| `SOURCE_DB_USER` | Source MySQL user | `cdc_user` |
| `SOURCE_DB_PASSWORD` | Source MySQL password | `secret` |
| `SOURCE_DB_NAME` | Source database name | `pos` |
| `TARGET_DB_HOST` | Target MySQL host | `192.168.0.104` |
| `TARGET_DB_PORT` | Target MySQL port | `3306` |
| `TARGET_DB_USER` | Target MySQL user | `cdc_writer` |
| `TARGET_DB_PASSWORD` | Target MySQL password | `secret` |
| `TARGET_DB_NAME` | Target database name | `pos_replica` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `KAFKA_BROKERS` | `localhost:9092` | Kafka/Redpanda brokers |
| `KAFKA_GROUP_ID` | `cdc-consumer-group` | Consumer group ID |
| `WORKER_COUNT` | `4` | Concurrent worker threads |
| `BATCH_SIZE` | `100` | Events per batch |
| `EXCLUDED_TABLES` | `recorded_order,lock,log` | Tables to skip |
| `LOG_LEVEL` | `info` | Log level (debug, info, warn, error) |
| `METRICS_PORT` | `9090` | Prometheus metrics port |
| `HEALTH_PORT` | `8081` | Health check port |
| `SOURCE_DB_TIMEZONE` | `America/Toronto` | Source DB timezone |
| `TARGET_DB_TIMEZONE` | `America/Toronto` | Target DB timezone |
| `DEBEZIUM_SERVER_ID` | Auto-generated | Unique MySQL server ID |

## Source Database Requirements

The source MySQL must have binlog enabled:

```sql
-- Check binlog status
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';

-- Required settings (in my.cnf):
-- log_bin = mysql-bin
-- binlog_format = ROW
-- binlog_row_image = FULL
-- server_id = 1
```

Create CDC user on source:

```sql
CREATE USER 'cdc_user'@'%' IDENTIFIED BY 'your_password';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'cdc_user'@'%';
FLUSH PRIVILEGES;
```

## Target Database Requirements

Create CDC writer user on target:

```sql
CREATE USER 'cdc_writer'@'%' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON pos_replica.* TO 'cdc_writer'@'%';
FLUSH PRIVILEGES;
```

## Build and Deploy

### Local Build

```bash
# Build binary
go build -o bin/cdc-consumer cmd/cdc-consumer/main.go

# Run tests
go test -v ./...

# Run linter (includes security scan)
golangci-lint run
```

### Docker Build

```bash
docker build -t pos-cdc-consumer .
```

### Jenkins CI/CD

The project includes three Jenkins pipelines:

| Pipeline | File | Purpose |
|----------|------|---------|
| CI | `Jenkinsfile` | Test, lint, security scan |
| Build | `Jenkinsfile.build` | Build and push Docker image to ghcr.io |
| Deploy | `Jenkinsfile.deploy` | Deploy to production server |

#### Required Jenkins Credentials

| Credential ID | Type | Description |
|---------------|------|-------------|
| `source-db-password` | Secret text | Source MySQL password |
| `target-db-password` | Secret text | Target MySQL password |
| `grafana-password` | Secret text | Grafana admin password |
| `ghcr-credentials` | Username/Password | GitHub Container Registry |
| `cdc-server-ssh-key` | SSH Key | Deployment server access |

#### Manual Deployment

```bash
# On production server
cd /opt/pos-cdc
git pull origin main

# Generate configs
ln -sf deployments/docker/.env .env
./scripts/set-debezium-config.sh

# Deploy
cd deployments/docker
docker compose up -d
```

## Useful Scripts

### Reset CDC Pipeline

Resets Debezium connector, clears Kafka topics, and optionally truncates target tables:

```bash
# Full reset (keeps target data)
./scripts/reset-cdc.sh

# Full reset with target truncation
./scripts/reset-cdc.sh --truncate-target
```

### Generate Debezium Config

Creates `configs/debezium-mysql-connector.json` from environment variables:

```bash
./scripts/set-debezium-config.sh
```

## Monitoring

### Health Endpoints

| Endpoint | Port | Description |
|----------|------|-------------|
| `/health` | 8081 | Liveness probe |
| `/ready` | 8081 | Readiness probe |
| `/metrics` | 9090 | Prometheus metrics |

### Grafana Dashboards

Access Grafana at `http://localhost:3000` (default: admin/admin)

### Key Metrics

- `cdc_events_processed_total` - Total events processed by operation type
- `cdc_events_failed_total` - Failed events (sent to DLQ)
- `cdc_batch_processing_duration_seconds` - Batch processing latency

## Troubleshooting

### Connector Won't Start

```bash
# Check connector status
curl http://localhost:8083/connectors/pos-mysql-connector/status | jq

# Check Debezium logs
docker logs debezium

# Common issues:
# - Source DB binlog not enabled
# - Wrong credentials
# - Server ID conflict (change DEBEZIUM_SERVER_ID)
```

### Consumer Not Processing Events

```bash
# Check if topics exist
docker exec redpanda rpk topic list | grep pos_mysql

# Check consumer group lag
docker exec redpanda rpk group describe cdc-consumer-group

# Reset consumer offset to beginning
docker exec redpanda rpk group seek cdc-consumer-group --to start
```

### Database Permission Errors

```sql
-- Check user grants on target
SHOW GRANTS FOR 'cdc_writer'@'%';

-- Should show:
-- GRANT ALL PRIVILEGES ON `pos_replica`.* TO `cdc_writer`@`%`
```

### Timezone Issues

If timestamps are off, verify timezone settings:

```sql
-- Check MySQL timezone
SELECT @@global.time_zone, @@session.time_zone;

-- Set timezone (MySQL 8)
SET GLOBAL time_zone = 'America/Toronto';
```

Ensure `SOURCE_DB_TIMEZONE` and `TARGET_DB_TIMEZONE` in `.env` match your databases.

### View Failed Events (DLQ)

```bash
# Check DLQ file
cat var/dlq/dlq.jsonl | jq

# Count failed events
wc -l var/dlq/dlq.jsonl
```

## Project Structure

```
pos-cdc/
├── cmd/
│   └── cdc-consumer/       # Main application entry point
├── configs/
│   └── debezium-mysql-connector.json.example
├── deployments/
│   └── docker/
│       ├── docker-compose.yml      # Base services
│       ├── docker-compose.dev.yml  # Dev overrides
│       └── docker-compose.prod.yml # Production overrides
├── internal/
│   ├── config/             # Configuration loading
│   ├── consumer/           # Kafka consumer
│   ├── health/             # Health check server
│   ├── models/             # Data models
│   ├── pool/               # Worker pool & DLQ
│   ├── processor/          # Event processing logic
│   └── writer/             # MySQL writer
├── pkg/
│   └── logger/             # Logging utilities
├── scripts/
│   ├── reset-cdc.sh        # Reset pipeline
│   └── set-debezium-config.sh  # Generate connector config
├── Dockerfile
├── Jenkinsfile             # CI pipeline
├── Jenkinsfile.build       # Build pipeline
├── Jenkinsfile.deploy      # Deploy pipeline
└── .golangci.yml           # Linter config
```

## License

Private repository - All rights reserved.
