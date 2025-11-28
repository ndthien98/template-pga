# Redis Master-Slave with Sentinel Failover

Production-ready Redis cluster with automatic failover using Redis Sentinel. Features 1 master, 3 slaves, 3 Sentinel instances, and comprehensive monitoring with Prometheus and Grafana.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Operational Commands](#operational-commands)
- [Monitoring](#monitoring)
- [Failover Testing](#failover-testing)
- [Troubleshooting](#troubleshooting)
- [Production Deployment](#production-deployment)

## Features

### High Availability
- ✅ **Automatic Failover**: Redis Sentinel monitors master and promotes slave on failure
- ✅ **3 Sentinel Instances**: Quorum-based decision making for failover
- ✅ **3 Slave Replicas**: Multiple read replicas for load distribution
- ✅ **Health Checks**: Automated health monitoring for all Redis instances

### Monitoring & Observability
- ✅ **Prometheus Integration**: Metrics collection from all Redis instances
- ✅ **Grafana Dashboards**: Pre-configured visualizations for Redis metrics
- ✅ **Redis Exporters**: Dedicated exporters for master and all slaves
- ✅ **Real-time Monitoring**: Track commands/sec, memory usage, replication lag

### Operational Excellence
- ✅ **Makefile Automation**: 25+ commands for common operations
- ✅ **Data Persistence**: AOF (Append-Only File) enabled for durability
- ✅ **Easy Backup**: Automated backup commands
- ✅ **Testing Tools**: Built-in replication and failover testing

## Architecture

### Service Layout

```
┌─────────────────┐
│  Redis Master   │ :6379
│  (Write/Read)   │
└────────┬────────┘
         │ Replication
         ├──────────────────┬──────────────────┐
         │                  │                  │
┌────────▼────────┐ ┌───────▼───────┐ ┌───────▼───────┐
│ Redis Slave 1   │ │ Redis Slave 2 │ │ Redis Slave 3 │
│ (Read Only)     │ │ (Read Only)   │ │ (Read Only)   │
│ :6380           │ │ :6381         │ │ :6382         │
└─────────────────┘ └───────────────┘ └───────────────┘
         │                  │                  │
         └──────────┬───────┴──────────────────┘
                    │ Monitored by
         ┌──────────▼───────────┐
         │  Redis Sentinels     │
         │  S1:26379            │
         │  S2:26380            │
         │  S3:26381            │
         └──────────────────────┘
```

### Monitoring Stack

```
Redis Instances
    │
    ├─> redis_exporter (per instance)
    │       │
    │       └─> Prometheus :9092
    │               │
    │               └─> Grafana :3001
    │
Sentinel Instances
    └─> Automatic Failover Management
```

### Ports

| Service | Internal Port | External Port | Description |
|---------|--------------|---------------|-------------|
| Redis Master | 6379 | 6379 | Primary Redis instance |
| Redis Slave 1 | 6379 | 6380 | First replica |
| Redis Slave 2 | 6379 | 6381 | Second replica |
| Redis Slave 3 | 6379 | 6382 | Third replica |
| Sentinel 1 | 26379 | 26379 | First Sentinel instance |
| Sentinel 2 | 26379 | 26380 | Second Sentinel instance |
| Sentinel 3 | 26379 | 26381 | Third Sentinel instance |
| Prometheus | 9090 | 9092 | Metrics database |
| Grafana | 3000 | 3001 | Monitoring dashboard |
| Redis Exporters | 9121 | 9121-9124 | Metrics exporters |

## Quick Start

### Prerequisites

- Docker (20.10+)
- Docker Compose (2.0+)
- Make (optional, for convenience commands)

### Start the Cluster

```bash
# Clone or navigate to this directory
cd redis-master-slave-with-failover

# Start all services
make up

# Check cluster health
make health

# View replication status
make status
```

### Test Replication

```bash
# Write data to master and verify on slaves
make test-replication
```

### Access Monitoring

- **Grafana**: http://localhost:3001 (admin/admin)
- **Prometheus**: http://localhost:9092

## Configuration

### Redis Configuration

#### Master Configuration (`config/redis-master.conf`)

Key settings:
- **Persistence**: AOF enabled with `everysec` fsync
- **Memory**: 256MB max with LRU eviction policy
- **Security**: Protected mode disabled (enable in production)

#### Slave Configuration (`config/redis-slave.conf`)

Key settings:
- **Read-Only**: Slaves are read-only by default
- **Replication**: Automatic synchronization from master
- **Persistence**: Same AOF settings as master

### Sentinel Configuration

#### Failover Settings

All Sentinels (`config/sentinel-*.conf`):
- **Quorum**: 2 Sentinels must agree for failover
- **Down After**: 5 seconds before marking master as down
- **Failover Timeout**: 10 seconds for failover completion
- **Parallel Syncs**: 1 slave at a time during reconfiguration

#### How Sentinel Failover Works

1. **Detection**: Sentinels continuously ping master
2. **Subjectively Down (SDOWN)**: Single Sentinel detects master down
3. **Objectively Down (ODOWN)**: Quorum of Sentinels agree master is down
4. **Leader Election**: Sentinels elect a leader to perform failover
5. **Slave Promotion**: Leader promotes a slave to master
6. **Reconfiguration**: Other slaves reconfigured to replicate from new master
7. **Notification**: Clients notified of new master address

### Monitoring Configuration

#### Prometheus (`config/prometheus.yml`)

- Scrapes all Redis exporters every 15 seconds
- Separate job for each Redis instance
- Labels for role (master/slave) and instance identification

#### Grafana Dashboard

Pre-configured panels:
- Redis master/slave status
- Connected clients
- Commands per second
- Memory usage (bytes and percentage)
- Keys per database
- Network I/O
- Replication lag

## Operational Commands

### Lifecycle Management

```bash
make up              # Start all services
make down            # Stop all services (keep data)
make restart         # Restart all services
make clean           # Stop and remove all data (DANGEROUS)
```

### Monitoring & Status

```bash
make status          # Show replication status
make health          # Check health of all instances
make sentinel-status # Show Sentinel configuration
make info            # Detailed Redis information
make logs            # Follow logs from all services
```

### Connection Commands

```bash
make connect-master      # Connect to Redis master
make connect-slave-1     # Connect to Redis slave 1
make connect-slave-2     # Connect to Redis slave 2
make connect-slave-3     # Connect to Redis slave 3
make connect-sentinel-1  # Connect to Sentinel 1
make connect-sentinel-2  # Connect to Sentinel 2
make connect-sentinel-3  # Connect to Sentinel 3
```

### Testing

```bash
make test-replication  # Test data replication
make test-failover     # Simulate master failure
make benchmark         # Run performance benchmark
```

### Data Management

```bash
make backup           # Backup Redis master data
make flush-all        # Delete all data (requires confirmation)
```

## Monitoring

### Access Grafana

1. Open http://localhost:3001
2. Login with `admin` / `admin`
3. Navigate to "Redis Cluster Monitoring" dashboard

### Key Metrics to Monitor

#### Performance Metrics
- **Commands/sec**: Request throughput
- **Hit Rate**: Cache efficiency (hits / (hits + misses))
- **Network I/O**: Data transfer rates

#### Health Metrics
- **Memory Usage**: Current vs. max memory
- **Replication Lag**: Bytes behind master
- **Connected Clients**: Active connections

#### Availability Metrics
- **Master Status**: Up/down indicator
- **Slave Count**: Number of connected slaves
- **Sentinel Consensus**: Quorum status

### Prometheus Queries

Useful PromQL queries:

```promql
# Total commands per second across cluster
sum(rate(redis_commands_processed_total[5m]))

# Memory usage percentage
redis_memory_used_bytes / redis_memory_max_bytes * 100

# Replication lag in bytes
redis_master_repl_offset{role="master"} - redis_slave_repl_offset{role="slave"}

# Hit rate percentage
rate(redis_keyspace_hits_total[5m]) / (rate(redis_keyspace_hits_total[5m]) + rate(redis_keyspace_misses_total[5m])) * 100
```

## Failover Testing

### Manual Failover Test

Test automatic failover by stopping the master:

```bash
# Run the automated failover test
make test-failover
```

This will:
1. Show current master address
2. Stop the master container
3. Wait 30 seconds for Sentinel to detect and failover
4. Show new master address
5. Display Sentinel status

### Recover Old Master

After failover testing, the old master can be recovered as a slave:

```bash
docker start redis-master
```

The old master will:
1. Start and attempt to come online as master
2. Be detected by Sentinel as wrong configuration
3. Be reconfigured automatically as a slave of new master
4. Sync data from new master

### Expected Failover Time

- **Detection**: ~5 seconds (configured `down-after-milliseconds`)
- **Election**: ~1-2 seconds (Sentinel leader election)
- **Promotion**: ~1-2 seconds (slave promotion)
- **Reconfiguration**: ~2-5 seconds (other slaves reconfigured)
- **Total**: ~10-15 seconds typical failover time

## Troubleshooting

### Common Issues

#### 1. Slaves Not Connecting to Master

**Symptoms**: Slaves show `master_link_status:down`

**Diagnosis**:
```bash
make status
docker logs redis-slave-1
```

**Solutions**:
- Verify master is running: `docker ps | grep redis-master`
- Check network connectivity: `docker network inspect redis-network`
- Verify master hostname resolution from slave

#### 2. Sentinel Not Detecting Master

**Symptoms**: No failover occurs when master is down

**Diagnosis**:
```bash
make sentinel-status
docker logs redis-sentinel-1
```

**Solutions**:
- Verify Sentinel configuration: `make connect-sentinel-1` then `SENTINEL masters`
- Check quorum setting (default: 2)
- Ensure at least 2 Sentinels are running
- Verify Sentinels can reach master

#### 3. Replication Lag

**Symptoms**: Slaves significantly behind master

**Diagnosis**:
```bash
make status
# Check replication lag in Grafana dashboard
```

**Solutions**:
- Check network bandwidth between master and slaves
- Verify slave resources (CPU, memory, disk I/O)
- Consider reducing write load on master
- Check `repl-diskless-sync` setting

#### 4. Memory Usage High

**Symptoms**: Redis using near max memory

**Diagnosis**:
```bash
make connect-master
> INFO memory
> MEMORY STATS
```

**Solutions**:
- Increase `maxmemory` in configuration
- Review eviction policy (current: `allkeys-lru`)
- Check for memory leaks (expired keys not cleaned)
- Use `MEMORY DOCTOR` for recommendations

### Debug Commands

```bash
# View Redis logs
docker logs redis-master
docker logs redis-slave-1

# View Sentinel logs
docker logs redis-sentinel-1

# Check container stats
docker stats redis-master

# Inspect network
docker network inspect redis-network

# Check replication details
docker exec redis-master redis-cli INFO replication

# Check Sentinel masters
docker exec redis-sentinel-1 redis-cli -p 26379 SENTINEL masters
```

## Production Deployment

### Security Hardening

#### 1. Enable Authentication

Edit `config/redis-master.conf` and `config/redis-slave.conf`:

```conf
# Set password for Redis
requirepass your_strong_password_here

# For slaves, also set master password
masterauth your_strong_password_here
```

Edit all `config/sentinel-*.conf`:

```conf
sentinel auth-pass mymaster your_strong_password_here
```

#### 2. Disable Protected Mode Carefully

Only disable protected mode if you have other security measures (firewall, VPN):

```conf
# Keep enabled if possible
protected-mode yes
```

#### 3. Use TLS/SSL

For production, enable Redis TLS:

```conf
tls-port 6380
tls-cert-file /path/to/redis.crt
tls-key-file /path/to/redis.key
tls-ca-cert-file /path/to/ca.crt
```

### Resource Sizing

#### Memory

- **Development**: 256MB per instance (current)
- **Small Production**: 1-2GB per instance
- **Medium Production**: 4-8GB per instance
- **Large Production**: 16GB+ per instance

Update in docker-compose.yml:

```yaml
command: >
  redis-server
  --maxmemory 2gb
```

#### CPU

- 1-2 cores for development
- 2-4 cores for production
- Scale based on commands/sec load

### Monitoring Alerts

Configure Prometheus alerts for:

1. **Master Down**: `redis_up{role="master"} == 0`
2. **High Memory**: `redis_memory_used_bytes / redis_memory_max_bytes > 0.9`
3. **Replication Lag**: `redis_master_repl_offset - redis_slave_repl_offset > 10000000`
4. **Low Hit Rate**: `rate(redis_keyspace_hits_total[5m]) / rate(redis_keyspace_total[5m]) < 0.8`
5. **Sentinel Quorum Lost**: `redis_sentinel_sentinels < 2`

### Backup Strategy

#### Automated Backups

Create a cron job for regular backups:

```bash
# Add to crontab
0 2 * * * cd /path/to/redis-master-slave-with-failover && make backup
```

#### Backup Retention

Keep backups based on your recovery point objective (RPO):
- Hourly backups: Last 24 hours
- Daily backups: Last 7 days
- Weekly backups: Last 4 weeks
- Monthly backups: Last 12 months

#### Disaster Recovery

Test restore procedure:

```bash
# Stop cluster
make down

# Restore backup
docker cp backups/dump-20250117-120000.rdb redis-master:/data/dump.rdb

# Start cluster
make up
```

### Performance Tuning

#### Optimize for Read-Heavy Workloads

```conf
# In redis.conf
maxmemory-policy allkeys-lru
lazyfree-lazy-eviction yes
```

#### Optimize for Write-Heavy Workloads

```conf
# Balance persistence vs performance
appendfsync no  # Maximum performance, risk of data loss
# OR
appendfsync everysec  # Good balance (default)
```

#### Connection Pooling

Use connection pooling in your application:
- Minimum: 5-10 connections
- Maximum: Based on Redis `maxclients` setting

### High Availability Checklist

- [ ] Enable Redis authentication
- [ ] Configure TLS/SSL for encryption
- [ ] Set up monitoring alerts
- [ ] Implement automated backups
- [ ] Test failover procedure
- [ ] Document runbooks for incidents
- [ ] Configure resource limits (CPU, memory)
- [ ] Set up log aggregation
- [ ] Implement connection pooling in clients
- [ ] Test disaster recovery procedure

## Client Connection

### Connecting with Sentinel Support

Most Redis clients support Sentinel for automatic master discovery:

#### Python (redis-py)

```python
from redis.sentinel import Sentinel

sentinel = Sentinel([
    ('localhost', 26379),
    ('localhost', 26380),
    ('localhost', 26381)
], socket_timeout=0.1)

# Get master
master = sentinel.master_for('mymaster', socket_timeout=0.1)
master.set('key', 'value')

# Get slave for read operations
slave = sentinel.slave_for('mymaster', socket_timeout=0.1)
value = slave.get('key')
```

#### Node.js (ioredis)

```javascript
const Redis = require('ioredis');

const sentinel = new Redis({
  sentinels: [
    { host: 'localhost', port: 26379 },
    { host: 'localhost', port: 26380 },
    { host: 'localhost', port: 26381 }
  ],
  name: 'mymaster'
});

sentinel.set('key', 'value');
```

#### Java (Jedis)

```java
Set<String> sentinels = new HashSet<>();
sentinels.add("localhost:26379");
sentinels.add("localhost:26380");
sentinels.add("localhost:26381");

JedisSentinelPool pool = new JedisSentinelPool("mymaster", sentinels);
Jedis jedis = pool.getResource();
jedis.set("key", "value");
```

## Architecture Decisions

### Why 3 Slaves?

- **High Availability**: Multiple failover candidates
- **Load Distribution**: Read queries distributed across slaves
- **Redundancy**: Tolerance for multiple simultaneous failures

### Why 3 Sentinels?

- **Quorum**: Need majority (2/3) to agree on failover
- **Fault Tolerance**: Cluster survives 1 Sentinel failure
- **Best Practice**: Odd number prevents split-brain scenarios

### Why Separate Sentinels from Redis?

- **Independence**: Sentinel failures don't affect Redis
- **Isolation**: Separate resource management
- **Flexibility**: Scale Sentinels independently

## License

MIT License - See repository LICENSE file for details

## Support

For issues, questions, or contributions:
- Check troubleshooting section above
- Review Redis documentation: https://redis.io/docs/
- Review Sentinel documentation: https://redis.io/topics/sentinel

## Related Documentation

- [PostgreSQL Master-Slave Template](../postgresql-master-slave-with-monitor/README.md)
- [Root Project Documentation](../CLAUDE.md)
- [Architectural Patterns](../CLAUDE-patterns.md)
