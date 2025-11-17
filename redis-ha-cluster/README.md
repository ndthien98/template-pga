# Redis High Availability Cluster with Sentinel

This setup provides a production-ready Redis high availability cluster with automatic failover using Redis Sentinel.

## Architecture

### Components

- **1 Redis Master**: Primary Redis instance accepting read/write operations
- **3 Redis Slaves**: Replica instances synchronized with the master (read-only)
- **3 Redis Sentinels**: Monitor the cluster and perform automatic failover

### Ports

| Service | Container Port | Host Port |
|---------|---------------|-----------|
| Redis Master | 6379 | 6379 |
| Redis Slave 1 | 6379 | 6380 |
| Redis Slave 2 | 6379 | 6381 |
| Redis Slave 3 | 6379 | 6382 |
| Sentinel 1 | 26379 | 26379 |
| Sentinel 2 | 26379 | 26380 |
| Sentinel 3 | 26379 | 26381 |

## Features

- **High Availability**: Automatic failover when master fails
- **Data Persistence**: Both RDB snapshots and AOF (Append-Only File)
- **Replication**: Real-time data sync from master to slaves
- **Monitoring**: Health checks for all Redis instances
- **Sentinel Quorum**: Requires 2 out of 3 sentinels to agree on failover

## Quick Start

### 1. Start the Cluster

```bash
docker-compose -f docker-compose.redis.yml up -d
```

### 2. Check Cluster Status

```bash
# Check all containers are running
docker-compose -f docker-compose.redis.yml ps

# Check master status
docker exec -it redis-master redis-cli INFO replication

# Check sentinel status
docker exec -it redis-sentinel-1 redis-cli -p 26379 SENTINEL masters
```

### 3. Test Replication

```bash
# Write to master
docker exec -it redis-master redis-cli SET test "Hello from master"

# Read from slave
docker exec -it redis-slave-1 redis-cli GET test
```

## Failover Testing

### Manual Failover Test

```bash
# Stop the master
docker stop redis-master

# Monitor sentinel logs to see failover
docker logs -f redis-sentinel-1

# Check new master (one of the slaves should be promoted)
docker exec -it redis-sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster

# Restart old master (it will become a slave)
docker start redis-master
```

### Automatic Failover

The cluster automatically performs failover when:
1. Master is unreachable for 5000ms (configurable in sentinel.conf)
2. At least 2 sentinels agree (quorum = 2)
3. A slave is promoted to master
4. Other slaves reconfigure to replicate from new master

## Configuration

### Redis Master/Slave Configuration

Located in `config/redis/master/redis.conf` and `config/redis/slave/redis.conf`

Key settings:
- **Persistence**: RDB + AOF enabled
- **Memory**: 256MB max with LRU eviction
- **Replication**: Slaves configured to replicate from master

### Sentinel Configuration

Located in `config/redis/sentinel/sentinel-{1,2,3}.conf`

Key settings:
- **Monitor**: Tracks master named "mymaster"
- **Quorum**: 2 (minimum sentinels to agree on failover)
- **Down-after-milliseconds**: 5000 (master down detection time)
- **Failover-timeout**: 10000 (max time for failover operation)
- **Parallel-syncs**: 1 (slaves to reconfigure simultaneously)

## Connecting to the Cluster

### From Application

Use a Redis client library that supports Sentinel:

**Node.js (ioredis)**
```javascript
const Redis = require('ioredis');

const redis = new Redis({
  sentinels: [
    { host: 'localhost', port: 26379 },
    { host: 'localhost', port: 26380 },
    { host: 'localhost', port: 26381 }
  ],
  name: 'mymaster'
});
```

**Python (redis-py)**
```python
from redis.sentinel import Sentinel

sentinel = Sentinel([
    ('localhost', 26379),
    ('localhost', 26380),
    ('localhost', 26381)
])

master = sentinel.master_for('mymaster', socket_timeout=0.1)
slave = sentinel.slave_for('mymaster', socket_timeout=0.1)

# Write to master
master.set('key', 'value')

# Read from slave
value = slave.get('key')
```

**Java (Jedis)**
```java
Set<String> sentinels = new HashSet<>();
sentinels.add("localhost:26379");
sentinels.add("localhost:26380");
sentinels.add("localhost:26381");

JedisSentinelPool pool = new JedisSentinelPool("mymaster", sentinels);
```

### Direct Connection (for testing)

```bash
# Connect to master
redis-cli -h localhost -p 6379

# Connect to slave
redis-cli -h localhost -p 6380

# Connect to sentinel
redis-cli -h localhost -p 26379
```

## Monitoring Commands

### Sentinel Commands

```bash
# Get master info
SENTINEL masters

# Get master address
SENTINEL get-master-addr-by-name mymaster

# Get slave info
SENTINEL slaves mymaster

# Get sentinel info
SENTINEL sentinels mymaster

# Check if master is down
SENTINEL ckquorum mymaster

# Force failover (manual)
SENTINEL failover mymaster
```

### Redis Replication Commands

```bash
# Check replication status
INFO replication

# Check connected slaves
INFO replication | grep connected_slaves

# Check slave lag
INFO replication | grep slave0
```

## Data Persistence

### RDB (Redis Database Backup)
- Snapshots taken at intervals: 900s (1 change), 300s (10 changes), 60s (10000 changes)
- File: `dump.rdb` in `/data` directory

### AOF (Append-Only File)
- Every write operation logged
- Fsync: every second (balance between performance and durability)
- File: `appendonly.aof` in `/data` directory

## Security Considerations

### Recommended Production Settings

1. **Enable Authentication**
   ```conf
   # In redis.conf
   requirepass yourpassword
   masterauth yourpassword

   # In sentinel.conf
   sentinel auth-pass mymaster yourpassword
   ```

2. **Network Security**
   - Change `bind 0.0.0.0` to specific IPs
   - Enable `protected-mode yes`
   - Use firewall rules to restrict access

3. **Use TLS/SSL**
   - Configure Redis with TLS certificates
   - Update client connections to use SSL

## Scaling

### Adding More Slaves

1. Add new service in `docker-compose.redis.yml`
2. Configure it to replicate from master
3. Restart the cluster

### Adjusting Sentinel Quorum

- Odd number of sentinels recommended (3, 5, 7)
- Quorum should be: (total_sentinels / 2) + 1
- Update `sentinel monitor` line in all sentinel configs

## Troubleshooting

### Master Not Reachable

```bash
# Check master is running
docker ps | grep redis-master

# Check sentinel logs
docker logs redis-sentinel-1
```

### Replication Lag

```bash
# Check on slave
docker exec -it redis-slave-1 redis-cli INFO replication | grep master_last_io_seconds_ago
```

### Sentinel Not Detecting Master

```bash
# Check sentinel can reach master
docker exec -it redis-sentinel-1 redis-cli -p 26379 PING

# Check sentinel configuration
docker exec -it redis-sentinel-1 cat /etc/redis/sentinel.conf
```

## Cleanup

```bash
# Stop all containers
docker-compose -f docker-compose.redis.yml down

# Remove volumes (deletes all data)
docker-compose -f docker-compose.redis.yml down -v
```

## Production Recommendations

1. **Resource Limits**: Add CPU and memory limits to docker-compose
2. **Monitoring**: Integrate with Prometheus/Grafana
3. **Backups**: Regular RDB/AOF backups to external storage
4. **Networking**: Use overlay network for multi-host deployments
5. **Testing**: Regular failover drills to ensure cluster health
6. **Logging**: Centralized logging with ELK or similar stack
