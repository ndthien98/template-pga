# PostgreSQL Master-Slave Replication with Monitoring

This project provides a complete Docker-based setup for PostgreSQL with master-slave replication, slow query logging, and comprehensive monitoring using Prometheus and Grafana.

## Architecture

- 1 PostgreSQL Master (port 5432)
- 2 PostgreSQL Replicas (ports 5433, 5434)
- PostgreSQL Exporters for each instance
- Prometheus for metrics collection
- Grafana for visualization

## Features

- Master-slave replication with automatic setup
- Slow query logging (queries > 100ms)
- pg_stat_statements extension for query performance tracking
- Real-time monitoring dashboards
- CPU and RAM usage tracking
- Top 10 slowest queries visualization
- Replication lag monitoring
- Database size tracking
- Transaction rate monitoring

## Prerequisites

- Docker
- Docker Compose

## Quick Start

### 1. Start the Infrastructure

```bash
docker-compose up -d
```

This will start:
- PostgreSQL master on port 5432
- PostgreSQL replica-1 on port 5433
- PostgreSQL replica-2 on port 5434
- Prometheus on port 9090
- Grafana on port 3000

### 2. Verify Replication Status

Connect to the master database:

```bash
docker exec -it pg-master psql -U postgres -d mydb
```

Check replication status:

```sql
SELECT * FROM pg_stat_replication;
```

You should see two replicas connected.

### 3. Access Grafana Dashboard

1. Open your browser and navigate to: http://localhost:3000
2. Login with default credentials:
   - Username: `admin`
   - Password: `admin`
3. The "PostgreSQL Monitoring - Slow Queries & System Metrics" dashboard should be automatically loaded

## Dashboard Panels

The Grafana dashboard includes:

1. **PostgreSQL CPU Usage**: Real-time CPU usage for all instances
2. **PostgreSQL Memory Usage**: RAM consumption tracking
3. **Top 10 Slowest Queries**: Table showing queries with highest mean execution time
4. **Query Execution Time Trends**: Time-series graph of query performance
5. **Active Database Connections**: Number of active connections per database
6. **Replication Lag**: Gauge showing replication delay in seconds
7. **Database Size**: Growth tracking for each database
8. **Transaction Rate**: Commits and rollbacks per second

## Configuration

### Slow Query Threshold

To adjust the slow query threshold, edit the PostgreSQL configuration files:

**Master**: `config/master/postgresql.conf`
**Replicas**: `config/replica/postgresql.conf`

```conf
log_min_duration_statement = 100  # milliseconds
```

### Database Credentials

Default credentials (change in production):
- User: `postgres`
- Password: `postgres`
- Database: `mydb`

Update in `docker-compose.yml`:

```yaml
environment:
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: postgres
  POSTGRES_DB: mydb
```

## Testing Replication

### Insert Data on Master

```bash
docker exec -it pg-master psql -U postgres -d mydb -c "CREATE TABLE test (id SERIAL PRIMARY KEY, name VARCHAR(100));"
docker exec -it pg-master psql -U postgres -d mydb -c "INSERT INTO test (name) VALUES ('test-data');"
```

### Verify on Replica

```bash
docker exec -it pg-replica-1 psql -U postgres -d mydb -c "SELECT * FROM test;"
```

## Generating Slow Queries for Testing

To test slow query monitoring:

```bash
docker exec -it pg-master psql -U postgres -d mydb
```

Run slow queries:

```sql
-- Create a table with data
CREATE TABLE test_performance (
    id SERIAL PRIMARY KEY,
    data TEXT
);

INSERT INTO test_performance (data)
SELECT md5(random()::text)
FROM generate_series(1, 100000);

-- Run a slow query
SELECT * FROM test_performance WHERE data LIKE '%abc%';

-- Check slow queries
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC
LIMIT 10;
```

## Monitoring Endpoints

- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9090
- **PostgreSQL Master Exporter**: http://localhost:9187/metrics
- **PostgreSQL Replica-1 Exporter**: http://localhost:9188/metrics
- **PostgreSQL Replica-2 Exporter**: http://localhost:9189/metrics

## Useful Commands

### View PostgreSQL Logs

```bash
# Master logs
docker logs -f pg-master

# Replica logs
docker logs -f pg-replica-1
docker logs -f pg-replica-2
```

### Connect to Databases

```bash
# Master
docker exec -it pg-master psql -U postgres -d mydb

# Replica 1
docker exec -it pg-replica-1 psql -U postgres -d mydb

# Replica 2
docker exec -it pg-replica-2 psql -U postgres -d mydb
```

### Check Replication Lag

```bash
docker exec -it pg-master psql -U postgres -d mydb -c "SELECT client_addr, application_name, state, sync_state, replay_lag FROM pg_stat_replication;"
```

### View pg_stat_statements

```bash
docker exec -it pg-master psql -U postgres -d mydb -c "SELECT query, calls, mean_exec_time, max_exec_time FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"
```

### Reset Statistics

```bash
docker exec -it pg-master psql -U postgres -d mydb -c "SELECT pg_stat_statements_reset();"
```

## Backup and Recovery

### Backup Master Database

```bash
docker exec pg-master pg_dump -U postgres mydb > backup.sql
```

### Restore to Master

```bash
cat backup.sql | docker exec -i pg-master psql -U postgres mydb
```

## Troubleshooting

### Replicas Not Connecting

1. Check master logs: `docker logs pg-master`
2. Verify pg_hba.conf allows replication connections
3. Check network connectivity: `docker network inspect template-pg_pg-network`

### Metrics Not Showing in Grafana

1. Verify Prometheus is scraping: http://localhost:9090/targets
2. Check exporter health: http://localhost:9187/metrics
3. Restart Grafana: `docker-compose restart grafana`

### Slow Queries Not Appearing

1. Verify pg_stat_statements extension:
   ```bash
   docker exec -it pg-master psql -U postgres -d mydb -c "SELECT * FROM pg_extension WHERE extname = 'pg_stat_statements';"
   ```
2. Run some queries to generate data
3. Check if queries are being logged:
   ```bash
   docker exec -it pg-master psql -U postgres -d mydb -c "SELECT COUNT(*) FROM pg_stat_statements;"
   ```

## Cleanup

To stop and remove all containers, volumes, and networks:

```bash
docker-compose down -v
```

To keep the data:

```bash
docker-compose down
```

## Production Considerations

1. **Security**:
   - Change default passwords
   - Use SSL/TLS for connections
   - Implement proper firewall rules
   - Use secrets management

2. **Performance**:
   - Tune PostgreSQL parameters based on your workload
   - Adjust shared_buffers, effective_cache_size, work_mem
   - Monitor and optimize slow queries regularly

3. **High Availability**:
   - Consider implementing automatic failover (e.g., Patroni)
   - Set up connection pooling (e.g., PgBouncer)
   - Implement proper backup strategies

4. **Monitoring**:
   - Set up alerting in Grafana
   - Configure retention policies in Prometheus
   - Implement log aggregation (e.g., ELK stack)

## File Structure

```
.
├── docker-compose.yml
├── config/
│   ├── master/
│   │   ├── postgresql.conf
│   │   └── pg_hba.conf
│   ├── replica/
│   │   └── postgresql.conf
│   ├── prometheus.yml
│   ├── postgres-exporter-queries.yaml
│   └── grafana/
│       ├── provisioning/
│       │   ├── datasources/
│       │   │   └── prometheus.yml
│       │   └── dashboards/
│       │       └── default.yml
│       └── dashboards/
│           └── postgresql-monitoring.json
└── scripts/
    ├── master-init.sh
    └── replica-init.sh
```

## License

MIT

## Support

For issues and questions, please check the troubleshooting section or refer to:
- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Prometheus Documentation: https://prometheus.io/docs/
- Grafana Documentation: https://grafana.com/docs/
