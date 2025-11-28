# Redpanda Simple Setup with Docker Compose

A simple Redpanda deployment with producer and consumer examples using Docker Compose and Node.js. Redpanda is a Kafka-compatible streaming platform that's simpler, faster, and requires no Zookeeper.

## Features

- Redpanda (Kafka-compatible streaming platform)
- Redpanda Console for monitoring and management
- Built-in Schema Registry
- REST API (Pandaproxy)
- Simple Node.js producer that sends messages
- Simple Node.js consumer that receives messages
- Health checks for all services
- Makefile for easy operations
- No Zookeeper required

## Architecture

```
┌─────────────────────────────────────┐
│          Redpanda                   │
│  ┌──────────────────────────────┐   │
│  │ Kafka API (19092)            │   │
│  │ Schema Registry (18081)      │   │
│  │ REST API (18082)             │   │◄────┐
│  │ Admin API (19644)            │   │     │
│  └──────────────────────────────┘   │     │
└────────────┬────────────────────────┘     │
             │                              │
             │                     ┌────────┴──────────┐
             │                     │ Redpanda Console  │
             │                     │   Port: 8080      │
             │                     └───────────────────┘
        ┌────┴────┐
        │         │
    ┌───▼───┐ ┌──▼────┐
    │Producer│ │Consumer│
    │Node.js │ │Node.js │
    └────────┘ └────────┘
```

## Why Redpanda?

- **Kafka-compatible**: Drop-in replacement, uses same protocols
- **No Zookeeper**: Simpler architecture, fewer moving parts
- **Faster**: Written in C++, optimized for performance
- **Lower latency**: 10x lower p99 latency vs Kafka
- **Easier ops**: Single binary, built-in monitoring
- **Lightweight**: Lower resource usage

## Prerequisites

- Docker and Docker Compose
- Node.js (v14 or higher)
- npm

## Quick Start

### 1. Start Redpanda Infrastructure

```bash
cd kafka/

# Start all services
make up

# Check status
make status
```

Services will be available at:
- Kafka API: localhost:19092
- Redpanda Console: http://localhost:8080
- Schema Registry: localhost:18081
- REST API: localhost:18082
- Admin API: localhost:19644

### 2. Install Node.js Dependencies

```bash
make install
# or
npm install
```

### 3. Run Producer and Consumer

Open two terminal windows:

**Terminal 1 - Consumer:**
```bash
make consumer
```

**Terminal 2 - Producer:**
```bash
make producer
```

The producer will send 100 messages (one per second) to the `test-topic`, and the consumer will receive and display them in real-time.

## Project Structure

```
kafka/
├── docker-compose.yml    # Kafka infrastructure definition
├── producer.js           # Message producer script
├── consumer.js           # Message consumer script
├── package.json          # Node.js dependencies
├── Makefile              # Operational commands
└── README.md             # This file
```

## Services

### Redpanda
- **Image**: docker.redpanda.com/redpandadata/redpanda:v23.3.3
- **Ports**:
  - 19092 (Kafka API - external)
  - 18081 (Schema Registry)
  - 18082 (REST API / Pandaproxy)
  - 19644 (Admin API)
- **Configuration**:
  - Single broker dev setup
  - Auto-create topics enabled
  - Built-in Raft consensus (no Zookeeper needed)
  - Development mode optimized for local testing

### Redpanda Console
- **Image**: docker.redpanda.com/redpandadata/console:v2.4.3
- **Port**: 8080
- **Features**:
  - Modern web-based UI
  - Topic management and message inspection
  - Consumer group monitoring
  - Schema Registry integration
  - Real-time metrics and performance monitoring

## Makefile Commands

### Setup Commands
```bash
make up          # Start Redpanda and Console
make down        # Stop all services
make restart     # Restart all services
make clean       # Stop and remove all volumes
```

### Monitoring Commands
```bash
make logs         # Follow logs from all services
make status       # Check health status and cluster info
make console      # Open Redpanda Console in browser
make cluster-info # Display detailed cluster information
```

### Topic Management
```bash
make topics              # List all topics
make create-topic TOPIC=my-topic  # Create a new topic
```

### Node.js Scripts
```bash
make install     # Install dependencies
make producer    # Run producer
make consumer    # Run consumer
```

## Producer Script (producer.js)

The producer:
- Connects to Redpanda broker at localhost:19092
- Uses KafkaJS client (fully compatible with Redpanda)
- Sends 100 messages to `test-topic` (one per second)
- Each message contains:
  - Unique key
  - JSON payload with id, timestamp, data, and random value
- Automatically disconnects after sending all messages

**Message Format:**
```json
{
  "id": 0,
  "timestamp": "2025-01-19T10:30:00.000Z",
  "data": "Message number 0",
  "randomValue": 42.5
}
```

## Consumer Script (consumer.js)

The consumer:
- Connects to Redpanda broker at localhost:19092
- Uses KafkaJS client (fully compatible with Redpanda)
- Subscribes to `test-topic` from the beginning
- Consumer group: `test-group`
- Displays detailed information for each message:
  - Topic, partition, and offset
  - Message key and value
  - Timestamp
- Runs continuously until stopped (Ctrl+C)

## Usage Examples

### Example 1: Basic Usage

```bash
# Terminal 1: Start infrastructure
make up

# Terminal 2: Start consumer
make consumer

# Terminal 3: Run producer
make producer
```

### Example 2: Monitor with Redpanda Console

```bash
# Start services
make up

# Open Redpanda Console
make console

# Navigate to Topics → test-topic to see messages
```

### Example 3: Create Custom Topic

```bash
# Create a new topic
make create-topic TOPIC=my-custom-topic

# List all topics
make topics
```

## Configuration

### Redpanda Configuration

Key settings in `docker-compose.yml`:
```yaml
--kafka-addr internal://0.0.0.0:9092,external://0.0.0.0:19092
--advertise-kafka-addr internal://redpanda:9092,external://localhost:19092
--mode dev-container  # Development mode
--smp 1              # Single-threaded for dev
```

**Why port 19092?**
- Redpanda uses 19092 for external Kafka API connections
- Port 9092 is for internal Docker network communication
- This prevents conflicts with local Kafka installations

### Producer Configuration

Located in `producer.js`:
```javascript
const kafka = new Kafka({
  clientId: 'my-producer',
  brokers: ['localhost:19092']  // Redpanda external port
});
```

### Consumer Configuration

Located in `consumer.js`:
```javascript
const consumer = kafka.consumer({
  groupId: 'test-group',
  sessionTimeout: 30000,
  heartbeatInterval: 3000
});
```

## Customization

### Change Topic Name

Edit both `producer.js` and `consumer.js`:
```javascript
const TOPIC = 'your-topic-name';
```

### Modify Message Interval

Edit `producer.js`:
```javascript
}, 1000); // Change interval (milliseconds)
```

### Change Number of Messages

Edit `producer.js`:
```javascript
if (messageCount >= 100) { // Change limit
```

## Monitoring

### Using Redpanda Console
1. Open http://localhost:8080
2. Navigate to Topics → test-topic
3. View messages, partitions, and consumer groups
4. Monitor cluster health and performance metrics
5. Explore Schema Registry (if using schemas)

### Using rpk CLI
```bash
# Cluster health
make status

# Cluster info
make cluster-info

# List topics
make topics

# Topic details
docker exec redpanda rpk topic describe test-topic
```

### Using Docker Logs
```bash
# All services
make logs

# Specific service
docker-compose logs -f redpanda
docker-compose logs -f redpanda-console
```

### Check Service Health
```bash
make status
```

## Troubleshooting

### Services Won't Start

```bash
# Clean everything and restart
make clean
make up
```

### Cannot Connect to Redpanda

```bash
# Check if Redpanda is healthy
docker-compose ps

# View Redpanda logs
docker-compose logs redpanda

# Check cluster health
make status

# Ensure port 19092 is not in use
lsof -i :19092
```

### Producer/Consumer Errors

```bash
# Reinstall dependencies
rm -rf node_modules package-lock.json
make install

# Check if Redpanda is accessible
telnet localhost 19092
```

### Topic Not Found

```bash
# List topics
make topics

# Redpanda auto-creates topics, but you can create manually:
make create-topic TOPIC=test-topic
```

### Port Conflicts

If you have Kafka running locally:
```bash
# Redpanda uses different ports (19092) to avoid conflicts
# But if you need to change ports, edit docker-compose.yml:
# Change "19092:19092" to "YOUR_PORT:19092"
```

## Production Considerations

This setup is designed for development and testing. For production:

1. **Security**:
   - Enable TLS encryption for all connections
   - Implement SASL authentication (SCRAM or OIDC)
   - Use ACLs for authorization
   - Enable Schema Registry authentication

2. **High Availability**:
   - Deploy 3+ Redpanda brokers for HA
   - Increase replication factor to 3
   - Configure rack awareness for fault tolerance
   - No Zookeeper needed - Redpanda uses built-in Raft

3. **Performance**:
   - Remove `--mode dev-container` flag
   - Increase `--smp` to match CPU cores
   - Tune memory settings (`--memory`)
   - Configure proper partition count based on load
   - Use producer batching and compression

4. **Monitoring**:
   - Enable Prometheus metrics endpoint
   - Set up alerting for lag and errors
   - Monitor disk usage and throughput
   - Use Redpanda Console for real-time monitoring

5. **Data Retention**:
   - Configure retention policies per topic
   - Set tiered storage for long-term retention
   - Implement backup strategy
   - Monitor disk space proactively

6. **Resource Tuning**:
   - Allocate sufficient memory (8GB+ recommended)
   - Use fast SSD storage
   - Configure network bandwidth limits
   - Set proper file descriptor limits

## Advanced Usage

### Multiple Producers

Create multiple producer instances:
```bash
# Terminal 1
node producer.js

# Terminal 2
node producer.js
```

### Multiple Consumer Groups

Modify `consumer.js` to use different group IDs:
```javascript
groupId: 'test-group-2'
```

Each consumer group will receive all messages independently.

### Partitioned Topics

```bash
# Using Makefile (creates 3 partitions by default)
make create-topic TOPIC=partitioned-topic

# Using rpk directly
docker exec redpanda rpk topic create partitioned-topic \
  --partitions 6 --replicas 1
```

### Using Schema Registry

```bash
# Schema Registry is available at localhost:18081
# Use it with Avro, Protobuf, or JSON Schema

# Example: Register a schema
curl -X POST http://localhost:18081/subjects/test-topic-value/versions \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d '{"schema":"{\"type\":\"record\",\"name\":\"Test\",\"fields\":[{\"name\":\"id\",\"type\":\"int\"}]}"}'
```

## Clean Up

```bash
# Stop services but keep data
make down

# Stop services and remove all data
make clean
```

## Dependencies

- **kafkajs**: ^2.2.4 - Node.js Kafka client
- **Docker**: For containerization
- **Docker Compose**: For orchestration

## License

MIT License

## Redpanda vs Kafka

| Feature | Redpanda | Kafka |
|---------|----------|-------|
| **Language** | C++ | Java/Scala |
| **Metadata Store** | Built-in Raft | Requires Zookeeper |
| **Latency (p99)** | ~10ms | ~100ms+ |
| **Memory Usage** | Lower | Higher (JVM) |
| **Setup** | Single binary | Multiple components |
| **API Compatibility** | 100% Kafka compatible | N/A |
| **License** | BSL | Apache 2.0 |

## Resources

- [Redpanda Documentation](https://docs.redpanda.com/)
- [Redpanda GitHub](https://github.com/redpanda-data/redpanda)
- [KafkaJS Documentation](https://kafka.js.org/)
- [Redpanda Console](https://docs.redpanda.com/docs/reference/console/)
- [rpk CLI Reference](https://docs.redpanda.com/docs/reference/rpk/)

## Support

For issues or questions:
1. Check Redpanda logs: `make logs`
2. Verify cluster health: `make status`
3. Review Redpanda Console: http://localhost:8080
4. Check cluster info: `make cluster-info`
5. Consult Redpanda documentation

## Next Steps

- Add error handling and retry logic
- Implement message validation with Schema Registry
- Add transaction support
- Integrate with Prometheus/Grafana monitoring
- Scale to multiple brokers (3+ for HA)
- Implement SASL authentication
- Add TLS encryption
- Configure tiered storage
- Set up backup and disaster recovery
