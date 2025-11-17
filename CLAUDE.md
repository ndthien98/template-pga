# Database Infrastructure Templates - Project Overview

## Project Description

This repository contains production-ready database infrastructure templates featuring replication, monitoring, and operational best practices. Each template is built with Docker and Docker Compose for easy deployment and scaling.

## Repository Structure

```
template-pg/
├── postgresql-master-slave-with-monitor/   # PostgreSQL replication with monitoring
│   ├── config/                              # PostgreSQL, Prometheus, Grafana configs
│   ├── scripts/                             # Initialization scripts
│   ├── docker-compose.yml                   # Complete infrastructure definition
│   ├── Makefile                             # Operational commands
│   └── README.md                            # Detailed documentation
├── redis-master-slave-with-failover/        # Redis Sentinel setup (planned)
├── .claude/                                 # Claude Code configuration
│   ├── agents/                              # Custom agent definitions
│   ├── commands/                            # Slash commands
│   └── skills/                              # Specialized skills
├── CLAUDE.md                                # This file - project overview
├── CLAUDE-activeContext.md                  # Current session context
├── CLAUDE-patterns.md                       # Architectural patterns
└── CLAUDE-todo-list.md                      # Task tracking
```

## Available Templates

### 1. PostgreSQL Master-Slave Replication with Monitoring

**Location**: `postgresql-master-slave-with-monitor/`

**Status**: ✅ Production-Ready

**Description**: A complete PostgreSQL 16 replication setup with master-slave architecture, comprehensive monitoring via Prometheus and Grafana, and slow query logging capabilities.

## Architecture

### Database Tier
- **PostgreSQL 16 (Alpine)** - Lightweight, secure base image
- **1 Master Node** (port 5432) - Primary write database
- **2 Replica Nodes** (ports 5433, 5434) - Read replicas with automatic synchronization
- **Streaming Replication** - Real-time data synchronization using PostgreSQL's built-in WAL-based replication

### Monitoring Stack
- **Prometheus** (port 9091) - Metrics collection and time-series database
- **Grafana** (port 3000) - Visualization dashboards with pre-configured panels
- **PostgreSQL Exporters** - Dedicated exporters for each database instance
  - Master exporter: port 9190
  - Replica-1 exporter: port 9188
  - Replica-2 exporter: port 9189

### Network Architecture
- All services communicate via a dedicated Docker bridge network (`pg-network`)
- Health checks configured for all PostgreSQL instances
- Dependency management ensures proper startup order

## Key Features

### 1. Automatic Replication Setup
- Replicas automatically connect to master on first startup
- Uses `pg_basebackup` for initial data sync
- Automatic recovery and reconnection on failures
- Replication lag monitoring

### 2. Query Performance Monitoring
- **pg_stat_statements** extension enabled for detailed query analytics
- Slow query logging threshold: 100ms (configurable)
- Tracks query execution time, call counts, and statistics
- Custom slow_query_log table for persistent storage

### 3. Comprehensive Logging
- All SQL statements logged
- Connection/disconnection events tracked
- Lock wait monitoring
- Checkpoint and temp file logging
- Structured log format with timestamps, user, database, and client info

### 4. Production-Ready Monitoring
Pre-configured Grafana dashboards showing:
- PostgreSQL CPU usage per instance
- Memory consumption tracking
- Top 10 slowest queries with execution statistics
- Query execution time trends
- Active database connections
- Replication lag gauge
- Database size growth
- Transaction rate (commits/rollbacks per second)

### 5. Data Persistence
- Named Docker volumes for all databases
- Prometheus and Grafana data persistence
- Backup and restore functionality via Makefile

### 2. Redis Master-Slave with Sentinel Failover

**Location**: `redis-master-slave-with-failover/`

**Status**: 🚧 Planned (directory created, implementation pending)

**Description**: Redis replication setup with automatic failover using Redis Sentinel for high availability.

## PostgreSQL Template - Detailed Architecture

### Database Tier
- **PostgreSQL 16 (Alpine)** - Lightweight, secure base image
- **1 Master Node** (port 5432) - Primary write database
- **2 Replica Nodes** (ports 5433, 5434) - Read replicas with automatic synchronization
- **Streaming Replication** - Real-time data synchronization using PostgreSQL's built-in WAL-based replication

### Monitoring Stack
- **Prometheus** (port 9091) - Metrics collection and time-series database
- **Grafana** (port 3000) - Visualization dashboards with pre-configured panels
- **PostgreSQL Exporters** - Dedicated exporters for each database instance
  - Master exporter: port 9190
  - Replica-1 exporter: port 9188
  - Replica-2 exporter: port 9189

### PostgreSQL Template Directory Structure

```
postgresql-master-slave-with-monitor/
├── config/                          # Configuration files
│   ├── master/
│   │   ├── postgresql.conf          # Master PostgreSQL config (replication, logging, performance)
│   │   └── pg_hba.conf              # Master access control (allows replication connections)
│   ├── replica/
│   │   └── postgresql.conf          # Replica PostgreSQL config (hot standby settings)
│   ├── prometheus.yml               # Prometheus scrape configuration
│   ├── postgres-exporter-queries.yaml  # Custom metrics queries
│   └── grafana/
│       ├── provisioning/
│       │   ├── datasources/
│       │   │   └── prometheus.yml   # Auto-configure Prometheus as data source
│       │   └── dashboards/
│       │       └── default.yml      # Auto-load dashboards
│       └── dashboards/
│           └── postgresql-monitoring.json  # Pre-built monitoring dashboard
├── scripts/
│   ├── master-init.sh               # Master initialization (create replicator user, extensions)
│   └── replica-init.sh              # Replica initialization script
├── docker-compose.yml               # Complete infrastructure definition
├── Makefile                         # Operational commands
├── start.sh                         # Quick start script
├── README.md                        # User documentation
└── .env.example                     # Environment variables template
```

## Technical Configuration

### PostgreSQL Master Settings
**File**: `postgresql-master-slave-with-monitor/config/master/postgresql.conf`

Key configurations:
- `wal_level = replica` - Enable WAL-based replication
- `max_wal_senders = 10` - Support up to 10 replicas
- `max_replication_slots = 10` - Replication slot management
- `wal_keep_size = 1GB` - Retain WAL files for replica recovery
- `shared_preload_libraries = 'pg_stat_statements'` - Load performance extension
- `log_min_duration_statement = 100` - Log queries > 100ms
- `shared_buffers = 256MB` - Memory for caching
- `effective_cache_size = 1GB` - Expected OS cache size

### Replica Configuration
- Automatically configured via `pg_basebackup -R` flag
- `postgresql.auto.conf` created with `primary_conninfo`
- Hot standby mode enabled for read queries

### Replication User
- Username: `replicator`
- Password: `replicator_password` (change in production)
- Role: `REPLICATION LOGIN`
- Created by `postgresql-master-slave-with-monitor/scripts/master-init.sh`

### Default Database Credentials
- User: `postgres`
- Password: `postgres`
- Database: `mydb`

**IMPORTANT**: Change all default passwords before production deployment.

## Getting Started

### Quick Start

```bash
# Navigate to PostgreSQL template
cd postgresql-master-slave-with-monitor/

# Start all services
make up

# Check replication status
make status

# Access Grafana dashboards
open http://localhost:3000  # Login: admin/admin
```

## Operational Commands (Makefile)

**Working Directory**: All make commands should be run from `postgresql-master-slave-with-monitor/`

### Basic Operations
- `make up` - Start all services with health checks
- `make down` - Stop all services (keep data)
- `make clean` - Stop and remove all data volumes
- `make restart` - Restart all services
- `make logs` - Follow logs from all services
- `make health` - Check health of all services

### Database Connections
- `make connect-master` - psql to master
- `make connect-replica-1` - psql to replica 1
- `make connect-replica-2` - psql to replica 2

### Testing & Verification
- `make status` - Check replication status and lag
- `make test-replication` - Create test table and verify data sync
- `make test-slow-query` - Generate slow queries for monitoring
- `make reset-stats` - Clear pg_stat_statements data

### Backup
- `make backup` - Create timestamped SQL dump of master database

## Monitoring Access

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Grafana | http://localhost:3000 | admin / admin |
| Prometheus | http://localhost:9090 | None |
| Master DB | localhost:5432 | postgres / postgres |
| Replica-1 DB | localhost:5433 | postgres / postgres |
| Replica-2 DB | localhost:5434 | postgres / postgres |

## Database Metrics Collected

Via postgres_exporter and custom queries:
- Connection counts and states
- Query execution statistics (pg_stat_statements)
- Replication lag and status
- Database sizes
- Transaction rates
- Cache hit ratios
- Slow query identification
- Lock information
- Index usage statistics

## Technology Stack

- **Database**: PostgreSQL 16 Alpine
- **Containerization**: Docker, Docker Compose v3.8
- **Monitoring**: Prometheus, Grafana
- **Metrics Export**: postgres_exporter (prometheuscommunity)
- **Orchestration**: Docker healthchecks, depends_on conditions
- **Automation**: Bash scripts, Makefile

## Production Considerations

### Security
- Change all default passwords
- Implement SSL/TLS for database connections
- Use Docker secrets instead of environment variables
- Configure firewall rules to restrict access
- Enable SSL for Grafana
- Use strong passwords for Grafana admin

### Performance Tuning
- Adjust `shared_buffers` based on available RAM (typically 25% of system RAM)
- Tune `work_mem` for complex queries (start with 16MB)
- Set `effective_cache_size` to 50-75% of total RAM
- Monitor and adjust `max_connections` based on load
- Consider connection pooling (PgBouncer) for high-traffic applications

### High Availability
- Consider implementing automatic failover (Patroni, repmgr)
- Set up health checks and alerting
- Implement backup rotation strategy
- Test disaster recovery procedures
- Consider using synchronous replication for critical data

### Scalability
- Add more replicas by duplicating replica service definition
- Implement read-write splitting in application layer
- Use load balancer for replica connections
- Monitor replication lag and scale accordingly

## Common Use Cases

1. **Development/Testing** - Local development with production-like setup
2. **Performance Testing** - Test query performance with realistic monitoring
3. **Training** - Learn PostgreSQL replication and monitoring
4. **Small Production** - Deploy for small to medium applications
5. **Template** - Starting point for customized PostgreSQL infrastructure

## Extension Points

- Add more replicas (copy replica service in docker-compose.yml)
- Implement PgBouncer for connection pooling
- Add backup automation (pg_dump + cron)
- Integrate log aggregation (ELK, Loki)
- Add alerting rules in Prometheus
- Custom Grafana dashboards for specific metrics
- Implement automated failover mechanism

## Git Repository Info

- Current branch: `main`
- Last commit: "pga = postgresql administrator"
- Status: Clean working directory

## Development Workflow

1. Make configuration changes in `config/` directory
2. Test with `make up`
3. Verify with `make status` and `make test-replication`
4. Check monitoring in Grafana
5. Commit changes with descriptive messages
6. Document any architectural changes in this file

## Important Files to Review

- `postgresql-master-slave-with-monitor/docker-compose.yml` - Complete service definitions
- `postgresql-master-slave-with-monitor/config/master/postgresql.conf` - Master database config
- `postgresql-master-slave-with-monitor/scripts/master-init.sh` - Initialization logic
- `postgresql-master-slave-with-monitor/Makefile` - Operational automation

## Quick Reference - PostgreSQL Template

**Navigate to directory**:
```bash
cd postgresql-master-slave-with-monitor/
```

**Common operations**:
- **Start everything**: `make up`
- **Check replication**: `make status`
- **Test replication**: `make test-replication`
- **View slow queries**: `make test-slow-query`
- **Access Grafana**: http://localhost:3000 (admin/admin)
- **Backup database**: `make backup`
- **Connect to master**: `make connect-master`
- **Clean everything**: `make clean`

## Repository Development

### Adding New Templates

When adding new database templates (e.g., Redis, MongoDB):

1. Create new directory: `{database}-{pattern}/`
2. Follow the PostgreSQL template structure
3. Include: docker-compose.yml, Makefile, README.md, config/, scripts/
4. Update root CLAUDE.md with template details
5. Add operational commands to template's Makefile
6. Document in template's README.md

### Current State

**PostgreSQL Template**: ✅ Complete and production-ready
**Redis Template**: 🚧 Directory created, implementation pending

## License

MIT License - See LICENSE file for details
