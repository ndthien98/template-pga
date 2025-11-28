.PHONY: help up down restart logs clean status health connect-master connect-slave-1 connect-slave-2 connect-slave-3 sentinel-status test-replication test-failover info backup

# Default target
help:
	@echo "Redis Master-Slave with Sentinel Failover - Available Commands:"
	@echo ""
	@echo "  Lifecycle Management:"
	@echo "    make up              - Start all Redis services (master, slaves, sentinels, monitoring)"
	@echo "    make down            - Stop all services (keep data volumes)"
	@echo "    make restart         - Restart all services"
	@echo "    make clean           - Stop services and remove all data volumes"
	@echo ""
	@echo "  Monitoring & Status:"
	@echo "    make status          - Show Redis replication status"
	@echo "    make health          - Check health of all Redis instances"
	@echo "    make sentinel-status - Show Sentinel configuration and status"
	@echo "    make info            - Show detailed Redis information"
	@echo "    make logs            - Follow logs from all services"
	@echo ""
	@echo "  Connection Commands:"
	@echo "    make connect-master  - Connect to Redis master with redis-cli"
	@echo "    make connect-slave-1 - Connect to Redis slave-1 with redis-cli"
	@echo "    make connect-slave-2 - Connect to Redis slave-2 with redis-cli"
	@echo "    make connect-slave-3 - Connect to Redis slave-3 with redis-cli"
	@echo "    make connect-sentinel-1 - Connect to Sentinel 1"
	@echo "    make connect-sentinel-2 - Connect to Sentinel 2"
	@echo "    make connect-sentinel-3 - Connect to Sentinel 3"
	@echo ""
	@echo "  Testing & Verification:"
	@echo "    make test-replication - Test replication by writing to master and reading from slaves"
	@echo "    make test-failover    - Simulate master failure to test automatic failover"
	@echo "    make benchmark        - Run redis-benchmark on master"
	@echo ""
	@echo "  Data Management:"
	@echo "    make backup          - Create backup of Redis master data"
	@echo "    make flush-all       - Delete all data from all databases (DANGEROUS)"
	@echo ""
	@echo "  Monitoring Access:"
	@echo "    Grafana:    http://localhost:3001 (admin/admin)"
	@echo "    Prometheus: http://localhost:9092"
	@echo ""

# Lifecycle Management
up:
	@echo "Starting Redis cluster with Sentinel failover..."
	docker-compose up -d
	@echo "Waiting for services to be ready..."
	@sleep 10
	@echo "Redis cluster is ready!"
	@echo ""
	@echo "Services running:"
	@echo "  Redis Master:    localhost:6379"
	@echo "  Redis Slave 1:   localhost:6380"
	@echo "  Redis Slave 2:   localhost:6381"
	@echo "  Redis Slave 3:   localhost:6382"
	@echo "  Sentinel 1:      localhost:26379"
	@echo "  Sentinel 2:      localhost:26380"
	@echo "  Sentinel 3:      localhost:26381"
	@echo "  Grafana:         http://localhost:3001"
	@echo "  Prometheus:      http://localhost:9092"

down:
	@echo "Stopping Redis cluster..."
	docker-compose down
	@echo "Redis cluster stopped (data volumes preserved)"

restart:
	@echo "Restarting Redis cluster..."
	docker-compose restart
	@echo "Redis cluster restarted"

clean:
	@echo "WARNING: This will delete all Redis data!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read confirm
	@echo "Stopping and removing all containers and volumes..."
	docker-compose down -v
	@echo "All data has been removed"

# Monitoring & Status
status:
	@echo "=== Redis Replication Status ==="
	@echo ""
	@echo "Master Status:"
	@docker exec redis-master redis-cli INFO replication
	@echo ""
	@echo "Slave 1 Status:"
	@docker exec redis-slave-1 redis-cli INFO replication | grep -E "role:|master_host:|master_port:|master_link_status:"
	@echo ""
	@echo "Slave 2 Status:"
	@docker exec redis-slave-2 redis-cli INFO replication | grep -E "role:|master_host:|master_port:|master_link_status:"
	@echo ""
	@echo "Slave 3 Status:"
	@docker exec redis-slave-3 redis-cli INFO replication | grep -E "role:|master_host:|master_port:|master_link_status:"

health:
	@echo "=== Redis Health Check ==="
	@echo ""
	@echo "Master:"
	@docker exec redis-master redis-cli ping || echo "Master is DOWN"
	@echo ""
	@echo "Slave 1:"
	@docker exec redis-slave-1 redis-cli ping || echo "Slave 1 is DOWN"
	@echo ""
	@echo "Slave 2:"
	@docker exec redis-slave-2 redis-cli ping || echo "Slave 2 is DOWN"
	@echo ""
	@echo "Slave 3:"
	@docker exec redis-slave-3 redis-cli ping || echo "Slave 3 is DOWN"
	@echo ""
	@echo "Sentinels:"
	@docker exec redis-sentinel-1 redis-cli -p 26379 ping || echo "Sentinel 1 is DOWN"
	@docker exec redis-sentinel-2 redis-cli -p 26379 ping || echo "Sentinel 2 is DOWN"
	@docker exec redis-sentinel-3 redis-cli -p 26379 ping || echo "Sentinel 3 is DOWN"

sentinel-status:
	@echo "=== Sentinel Status ==="
	@echo ""
	@echo "Sentinel 1 - Master Info:"
	@docker exec redis-sentinel-1 redis-cli -p 26379 SENTINEL master mymaster
	@echo ""
	@echo "Sentinel 1 - Slaves Info:"
	@docker exec redis-sentinel-1 redis-cli -p 26379 SENTINEL slaves mymaster
	@echo ""
	@echo "Sentinel 1 - Sentinels Info:"
	@docker exec redis-sentinel-1 redis-cli -p 26379 SENTINEL sentinels mymaster

info:
	@echo "=== Redis Master Detailed Information ==="
	@docker exec redis-master redis-cli INFO

logs:
	@echo "Following logs from all services (Ctrl+C to exit)..."
	docker-compose logs -f

# Connection Commands
connect-master:
	@echo "Connecting to Redis Master..."
	docker exec -it redis-master redis-cli

connect-slave-1:
	@echo "Connecting to Redis Slave 1..."
	docker exec -it redis-slave-1 redis-cli

connect-slave-2:
	@echo "Connecting to Redis Slave 2..."
	docker exec -it redis-slave-2 redis-cli

connect-slave-3:
	@echo "Connecting to Redis Slave 3..."
	docker exec -it redis-slave-3 redis-cli

connect-sentinel-1:
	@echo "Connecting to Redis Sentinel 1..."
	docker exec -it redis-sentinel-1 redis-cli -p 26379

connect-sentinel-2:
	@echo "Connecting to Redis Sentinel 2..."
	docker exec -it redis-sentinel-2 redis-cli -p 26379

connect-sentinel-3:
	@echo "Connecting to Redis Sentinel 3..."
	docker exec -it redis-sentinel-3 redis-cli -p 26379

# Testing & Verification
test-replication:
	@echo "=== Testing Redis Replication ==="
	@echo ""
	@echo "1. Writing test data to master..."
	@docker exec redis-master redis-cli SET test_key "test_value_$$(date +%s)"
	@docker exec redis-master redis-cli SET test_counter "$$(date +%s)"
	@echo ""
	@echo "2. Reading from master:"
	@docker exec redis-master redis-cli GET test_key
	@echo ""
	@echo "3. Waiting for replication (2 seconds)..."
	@sleep 2
	@echo ""
	@echo "4. Reading from Slave 1:"
	@docker exec redis-slave-1 redis-cli GET test_key
	@echo ""
	@echo "5. Reading from Slave 2:"
	@docker exec redis-slave-2 redis-cli GET test_key
	@echo ""
	@echo "6. Reading from Slave 3:"
	@docker exec redis-slave-3 redis-cli GET test_key
	@echo ""
	@echo "If all slaves show the same value, replication is working correctly!"

test-failover:
	@echo "=== Testing Automatic Failover ==="
	@echo ""
	@echo "WARNING: This will stop the master container to trigger failover!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read confirm
	@echo ""
	@echo "1. Current master before failover:"
	@docker exec redis-sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
	@echo ""
	@echo "2. Stopping Redis master container..."
	@docker stop redis-master
	@echo ""
	@echo "3. Waiting for Sentinel to detect failure and elect new master (30 seconds)..."
	@sleep 30
	@echo ""
	@echo "4. New master after failover:"
	@docker exec redis-sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
	@echo ""
	@echo "5. Sentinel status:"
	@docker exec redis-sentinel-1 redis-cli -p 26379 SENTINEL master mymaster
	@echo ""
	@echo "To recover the old master as a slave, run: docker start redis-master"

benchmark:
	@echo "Running Redis benchmark on master (100000 requests)..."
	@docker exec redis-master redis-benchmark -q -n 100000

# Data Management
backup:
	@echo "Creating backup of Redis master data..."
	@mkdir -p ./backups
	@docker exec redis-master redis-cli BGSAVE
	@echo "Waiting for background save to complete..."
	@sleep 5
	@docker cp redis-master:/data/dump.rdb ./backups/dump-$$(date +%Y%m%d-%H%M%S).rdb
	@echo "Backup created in ./backups/"
	@ls -lh ./backups/

flush-all:
	@echo "WARNING: This will delete ALL data from ALL databases!"
	@echo "Type 'DELETE' to confirm:"
	@read confirm; \
	if [ "$$confirm" = "DELETE" ]; then \
		docker exec redis-master redis-cli FLUSHALL; \
		echo "All data has been deleted"; \
	else \
		echo "Operation cancelled"; \
	fi

# Additional utility commands
ps:
	@docker-compose ps

top:
	@docker stats --no-stream $$(docker-compose ps -q)

networks:
	@docker network inspect redis-network

volumes:
	@docker volume ls | grep redis
