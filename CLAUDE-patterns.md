# Architectural Patterns - Database Infrastructure Templates

## Overview

This document describes the architectural patterns, design decisions, and implementation approaches used across database infrastructure templates in this repository.

## Repository Pattern

### Multi-Template Repository Structure

**Pattern**: Template-based repository with isolated subdirectories

**Implementation**:
```
template-pg/
├── postgresql-master-slave-with-monitor/   # Complete PostgreSQL template
├── redis-master-slave-with-failover/       # Redis template (planned)
├── CLAUDE-*.md                              # Repository-level documentation
└── .claude/                                 # Shared Claude Code configuration
```

**Rationale**:
- Each template is self-contained and independently deployable
- Shared documentation and tooling at root level
- Easy to add new database templates
- Users can focus on one template without complexity of others
- Consistent structure across all templates

## PostgreSQL Template Patterns

All patterns below apply to the `postgresql-master-slave-with-monitor/` template.

## Infrastructure Patterns

### 1. Container Orchestration Pattern

**Pattern**: Multi-container application with service dependencies and health checks

**Implementation**:
- Docker Compose v3.8 for service orchestration
- Explicit service dependencies using `depends_on` with health conditions
- Health checks for all critical services (PostgreSQL instances)
- Named volumes for data persistence
- Custom bridge network for service isolation

**Code Reference**: `postgresql-master-slave-with-monitor/docker-compose.yml`

**Rationale**:
- Ensures proper startup order (master before replicas)
- Prevents cascading failures
- Enables automatic recovery
- Provides service isolation and security

### 2. Database Replication Pattern

**Pattern**: PostgreSQL streaming replication with WAL (Write-Ahead Logging)

**Implementation**:
```yaml
# Master configuration (postgresql-master-slave-with-monitor/config/master/postgresql.conf)
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
wal_keep_size = 1GB
hot_standby = on
```

**Replica Initialization**:
- Wait for master health check
- Execute `pg_basebackup` to clone master data
- Auto-configure `primary_conninfo` for continuous replication
- Start in hot standby mode

**Rationale**:
- Built-in PostgreSQL feature (no third-party tools)
- Asynchronous by default (performance)
- Automatic WAL streaming
- Replicas available for read queries (hot standby)

### 3. Metrics Collection Pattern

**Pattern**: Exporter-based metrics scraping with dedicated exporters per service

**Implementation**:
- One postgres_exporter per database instance
- Separate ports for each exporter (9190, 9188, 9189)
- Custom metrics queries via YAML configuration
- Prometheus scrapes all exporters every 15 seconds

**Code Reference**:
- Exporter definitions: `postgresql-master-slave-with-monitor/docker-compose.yml`
- Prometheus config: `postgresql-master-slave-with-monitor/config/prometheus.yml`

**Rationale**:
- Independent scaling of monitoring per database
- Isolated failures (one exporter down doesn't affect others)
- Custom metrics specific to database role (master vs replica)
- Standard prometheus_community/postgres-exporter image

### 4. Configuration Management Pattern

**Pattern**: External configuration files mounted as volumes

**Structure**:
```
postgresql-master-slave-with-monitor/config/
├── master/
│   ├── postgresql.conf      # Master-specific settings
│   └── pg_hba.conf           # Access control
├── replica/
│   └── postgresql.conf       # Replica-specific settings
├── prometheus.yml
├── postgres-exporter-queries.yaml
└── grafana/
    ├── provisioning/
    └── dashboards/
```

**Rationale**:
- Configuration changes without container rebuilds
- Version control for configuration
- Easy diff between master and replica configs
- Separation of concerns

### 5. Initialization Pattern

**Pattern**: Init scripts executed on first container startup

**Implementation**:
- Master: `postgresql-master-slave-with-monitor/scripts/master-init.sh` mounted to `/docker-entrypoint-initdb.d/`
- Replicas: Inline bash script in `command:` section
- Idempotent operations using `IF NOT EXISTS` checks

**Master Init**:
1. Create replication user with proper permissions
2. Enable pg_stat_statements extension
3. Create slow_query_log table
4. Grant necessary permissions

**Replica Init**:
1. Check if PGDATA is empty
2. Wait for master to be ready
3. Execute pg_basebackup
4. Configure primary_conninfo
5. Fix permissions

**Rationale**:
- Automatic setup on first run
- No manual configuration required
- Idempotent (safe to restart)
- Declarative infrastructure

### 6. Monitoring Dashboard Pattern

**Pattern**: Pre-provisioned Grafana dashboards with auto-loaded data sources

**Implementation**:
```yaml
# Grafana provisioning (postgresql-master-slave-with-monitor/config/grafana/provisioning/)
datasources/prometheus.yml    # Auto-add Prometheus
dashboards/default.yml         # Auto-load dashboard folder
dashboards/postgresql-monitoring.json  # Pre-built dashboard
```

**Dashboard Panels** (8 key metrics):
1. CPU usage per instance
2. Memory consumption
3. Top 10 slowest queries (pg_stat_statements)
4. Query execution time trends
5. Active connections
6. Replication lag
7. Database sizes
8. Transaction rates

**Rationale**:
- Zero configuration required after `make up`
- Consistent monitoring across deployments
- Best practices dashboard included
- Extensible (add custom panels)

### 7. Operational Automation Pattern

**Pattern**: Makefile-based operational commands

**Categories**:
- Lifecycle: `up`, `down`, `restart`, `clean`
- Connectivity: `connect-master`, `connect-replica-1`, `connect-replica-2`
- Testing: `test-replication`, `test-slow-query`
- Monitoring: `status`, `health`
- Maintenance: `backup`, `reset-stats`

**Code Reference**: `postgresql-master-slave-with-monitor/Makefile`

**Rationale**:
- Consistent command interface
- Self-documenting (`make help`)
- Reduces human error
- Encapsulates complex docker commands

## Data Flow Patterns

### Write Operations Flow

```
Client → Master (port 5432)
         ↓
     WAL Generation
         ↓
   WAL Streaming → Replica-1 (port 5433)
         ↓
   WAL Streaming → Replica-2 (port 5434)
```

### Read Operations Flow

```
Read-Write Client → Master (5432)
Read-Only Client → Replica-1 (5433) OR Replica-2 (5434)
```

### Metrics Flow

```
PostgreSQL Instance
    ↓ (internal stats)
pg_stat_statements
    ↓ (SQL queries)
postgres_exporter
    ↓ (HTTP /metrics)
Prometheus (scrape)
    ↓ (query API)
Grafana (visualization)
```

## Security Patterns

### 1. Network Isolation
- Custom Docker network (`pg-network`)
- No host network mode
- Explicit port mappings only

### 2. Access Control
**pg_hba.conf** (`postgresql-master-slave-with-monitor/config/master/pg_hba.conf`):
- Trust from localhost
- Password authentication for network connections
- Replication connections from Docker network

### 3. Secrets Management
**Current** (Development):
- Environment variables in docker-compose.yml
- Default passwords: `postgres`/`postgres`

**Production Recommendation**:
- Docker secrets
- External secret management (Vault, AWS Secrets Manager)
- Encrypted connections (SSL/TLS)

## Performance Patterns

### 1. Memory Configuration
```
shared_buffers = 256MB          # Cache frequently accessed data
effective_cache_size = 1GB      # OS + PostgreSQL cache
work_mem = 16MB                 # Per-operation memory
maintenance_work_mem = 128MB    # Vacuum, index creation
```

**Rationale**: Balanced for typical 2-4GB RAM system. Scale proportionally for production.

### 2. Connection Management
```
max_connections = 100
```

**Pattern**: Direct connections (no pooling in base template)

**Production Enhancement**: Add PgBouncer for connection pooling

### 3. WAL Configuration
```
wal_keep_size = 1GB
```

**Pattern**: Retain enough WAL for replica recovery after short downtime

**Tuning**: Increase if replicas frequently fall behind

### 4. Query Performance Tracking
```
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all
track_io_timing = on
```

**Pattern**: Comprehensive query statistics for optimization

## Logging Patterns

### 1. Structured Logging
```
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
```

**Pattern**: Consistent log format with contextual information

### 2. Slow Query Logging
```
log_min_duration_statement = 100  # milliseconds
log_statement = 'all'
log_duration = on
```

**Pattern**: Capture all queries, highlight slow ones (>100ms)

**Storage**:
- PostgreSQL logs (file-based)
- pg_stat_statements (in-database analysis)
- slow_query_log table (structured storage)

### 3. Operational Logging
```
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0
```

**Pattern**: Track all operational events for troubleshooting

## High Availability Patterns

### Current Implementation
- **Pattern**: Simple failover (manual)
- **Setup**: Master + 2 replicas
- **Data Loss**: Possible (asynchronous replication)
- **Failover**: Manual promotion

### Production Enhancement Options

**Option 1: Patroni**
- Automatic failover
- Distributed consensus (etcd/Consul/Zookeeper)
- Health checks and automatic promotion

**Option 2: repmgr**
- Replication cluster management
- Automated failover
- Simpler than Patroni

**Option 3: Synchronous Replication**
```
synchronous_commit = on
synchronous_standby_names = 'replica-1'
```
- Zero data loss
- Performance impact
- One replica guaranteed synchronized

## Extension Points

### 1. Adding More Replicas
**Pattern**: Copy-paste service definition
```yaml
pg-replica-3:
  # Copy pg-replica-2 definition
  # Change container_name, ports, volumes
```

### 2. Adding Connection Pooling
**Pattern**: PgBouncer sidecar
```yaml
pgbouncer:
  image: pgbouncer/pgbouncer
  # Configure pool size, auth
  depends_on: [pg-master]
```

### 3. Adding Backup Automation
**Pattern**: Cron sidecar container
```yaml
backup-cron:
  image: alpine
  # Install crond + pg_dump
  # Schedule backups
```

### 4. Adding Custom Metrics
**Pattern**: Extend postgres-exporter-queries.yaml
```yaml
custom_query:
  query: "SELECT ..."
  metrics:
    - name: custom_metric
      usage: GAUGE
```

## Anti-Patterns Avoided

### 1. ❌ Single Point of Failure
**Avoided**: Multiple replicas, health checks

### 2. ❌ Hardcoded Configuration
**Avoided**: External config files, environment variables

### 3. ❌ Manual Setup Steps
**Avoided**: Init scripts, automation via Makefile

### 4. ❌ Monitoring as Afterthought
**Avoided**: Integrated monitoring from day one

### 5. ❌ Data Loss on Container Restart
**Avoided**: Named volumes for persistence

## Best Practices Implemented

### 1. ✅ Infrastructure as Code
- Entire stack defined in docker-compose.yml
- Version controlled configuration
- Reproducible deployments

### 2. ✅ Observability First
- Pre-configured monitoring
- Comprehensive logging
- Query performance tracking

### 3. ✅ Operational Excellence
- Self-service commands (Makefile)
- Health checks
- Automated testing

### 4. ✅ Security Baseline
- Network isolation
- Access control configuration
- Clear production guidance

### 5. ✅ Documentation
- Comprehensive README
- CLAUDE.md overview
- Inline configuration comments

## Technology Decision Log

| Decision | Choice | Rationale | Date |
|----------|--------|-----------|------|
| PostgreSQL Version | 16 Alpine | Latest stable, small image size | Initial |
| Replication Method | Streaming (WAL) | Built-in, reliable, performant | Initial |
| Monitoring Stack | Prometheus + Grafana | Industry standard, extensible | Initial |
| Container Platform | Docker Compose | Simple, portable, no Kubernetes overhead | Initial |
| Metrics Exporter | postgres_exporter | Official, well-maintained | Initial |
| Base Image | Alpine Linux | Minimal attack surface, small size | Initial |
| Dashboard Tool | Grafana | Best-in-class visualization | Initial |
| Automation Tool | Makefile | Universal, simple, self-documenting | Initial |

## Pattern Evolution History

### Version 1.0 (Initial)
- Master-slave setup
- Basic monitoring
- Manual configuration

### Current Version
- Automated replica initialization
- Pre-provisioned dashboards
- Comprehensive logging
- Operational automation (Makefile)
- Health checks and dependencies

### Planned Improvements
- Automatic failover consideration
- Connection pooling example
- Backup automation
- SSL/TLS configuration example
- Multi-region replication pattern
