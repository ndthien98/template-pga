.PHONY: help up down restart logs clean status test-replication test-slow-query backup

help:
	@echo "PostgreSQL Master-Slave Monitoring Stack"
	@echo ""
	@echo "Available commands:"
	@echo "  make up                 - Start all services"
	@echo "  make down               - Stop all services"
	@echo "  make restart            - Restart all services"
	@echo "  make logs               - View logs from all services"
	@echo "  make clean              - Remove all containers and volumes"
	@echo "  make status             - Check replication status"
	@echo "  make test-replication   - Test replication functionality"
	@echo "  make test-slow-query    - Generate slow queries for testing"
	@echo "  make backup             - Backup master database"
	@echo "  make connect-master     - Connect to master database"
	@echo "  make connect-replica-1  - Connect to replica 1 database"
	@echo "  make connect-replica-2  - Connect to replica 2 database"

up:
	docker-compose up -d
	@echo "Waiting for services to be healthy..."
	@sleep 10
	@echo "Services started successfully!"
	@echo "Grafana: http://localhost:3000 (admin/admin)"
	@echo "Prometheus: http://localhost:9090"

down:
	docker-compose down

restart:
	docker-compose restart

logs:
	docker-compose logs -f

logs-master:
	docker logs -f pg-master

logs-replica-1:
	docker logs -f pg-replica-1

logs-replica-2:
	docker logs -f pg-replica-2

clean:
	docker-compose down -v
	@echo "All containers and volumes removed"

status:
	@echo "Checking replication status..."
	@docker exec -it pg-master psql -U postgres -d mydb -c "SELECT client_addr, application_name, state, sync_state, replay_lag FROM pg_stat_replication;"

test-replication:
	@echo "Creating test table on master..."
	@docker exec -it pg-master psql -U postgres -d mydb -c "CREATE TABLE IF NOT EXISTS replication_test (id SERIAL PRIMARY KEY, created_at TIMESTAMP DEFAULT NOW(), data TEXT);"
	@echo "Inserting test data on master..."
	@docker exec -it pg-master psql -U postgres -d mydb -c "INSERT INTO replication_test (data) VALUES ('Test data at $$(date)');"
	@echo ""
	@echo "Data on master:"
	@docker exec -it pg-master psql -U postgres -d mydb -c "SELECT * FROM replication_test ORDER BY id DESC LIMIT 5;"
	@echo ""
	@sleep 2
	@echo "Data on replica-1:"
	@docker exec -it pg-replica-1 psql -U postgres -d mydb -c "SELECT * FROM replication_test ORDER BY id DESC LIMIT 5;"
	@echo ""
	@echo "Data on replica-2:"
	@docker exec -it pg-replica-2 psql -U postgres -d mydb -c "SELECT * FROM replication_test ORDER BY id DESC LIMIT 5;"

test-slow-query:
	@echo "Creating test table with data..."
	@docker exec -it pg-master psql -U postgres -d mydb -c "CREATE TABLE IF NOT EXISTS slow_query_test (id SERIAL PRIMARY KEY, data TEXT);"
	@docker exec -it pg-master psql -U postgres -d mydb -c "INSERT INTO slow_query_test (data) SELECT md5(random()::text) FROM generate_series(1, 50000);"
	@echo ""
	@echo "Running slow query (this will take a moment)..."
	@docker exec -it pg-master psql -U postgres -d mydb -c "SELECT * FROM slow_query_test WHERE data LIKE '%abc%';"
	@echo ""
	@echo "Top 10 slowest queries:"
	@docker exec -it pg-master psql -U postgres -d mydb -c "SELECT LEFT(query, 80) as query, calls, ROUND(mean_exec_time::numeric, 2) as mean_ms, ROUND(max_exec_time::numeric, 2) as max_ms FROM pg_stat_statements WHERE mean_exec_time > 10 ORDER BY mean_exec_time DESC LIMIT 10;"

backup:
	@echo "Creating backup of master database..."
	@docker exec pg-master pg_dump -U postgres mydb > backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "Backup completed: backup_$$(date +%Y%m%d_%H%M%S).sql"

connect-master:
	docker exec -it pg-master psql -U postgres -d mydb

connect-replica-1:
	docker exec -it pg-replica-1 psql -U postgres -d mydb

connect-replica-2:
	docker exec -it pg-replica-2 psql -U postgres -d mydb

reset-stats:
	@echo "Resetting pg_stat_statements..."
	@docker exec -it pg-master psql -U postgres -d mydb -c "SELECT pg_stat_statements_reset();"
	@echo "Statistics reset successfully"

health:
	@echo "Checking health of all services..."
	@echo ""
	@echo "PostgreSQL Master:"
	@docker exec pg-master pg_isready -U postgres || echo "Master is not ready"
	@echo ""
	@echo "PostgreSQL Replica 1:"
	@docker exec pg-replica-1 pg_isready -U postgres || echo "Replica 1 is not ready"
	@echo ""
	@echo "PostgreSQL Replica 2:"
	@docker exec pg-replica-2 pg_isready -U postgres || echo "Replica 2 is not ready"
	@echo ""
	@echo "Prometheus:"
	@curl -s http://localhost:9090/-/healthy && echo "Prometheus is healthy" || echo "Prometheus is not healthy"
	@echo ""
	@echo "Grafana:"
	@curl -s http://localhost:3000/api/health && echo "" || echo "Grafana is not healthy"
