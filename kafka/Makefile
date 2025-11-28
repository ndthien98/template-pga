.PHONY: help up down restart logs clean install producer consumer console status topics create-topic list-topics cluster-info

help:
	@echo "Redpanda Docker Compose - Available Commands"
	@echo "============================================"
	@echo "Setup:"
	@echo "  make up          - Start Redpanda and Redpanda Console"
	@echo "  make down        - Stop all services"
	@echo "  make restart     - Restart all services"
	@echo "  make clean       - Stop and remove all volumes"
	@echo ""
	@echo "Monitoring:"
	@echo "  make logs        - Follow logs from all services"
	@echo "  make status      - Check health status of services"
	@echo "  make console     - Open Redpanda Console in browser"
	@echo "  make cluster-info - Display cluster information"
	@echo ""
	@echo "Topics:"
	@echo "  make topics      - List all topics"
	@echo "  make create-topic TOPIC=<name> - Create a new topic"
	@echo ""
	@echo "Node.js Scripts:"
	@echo "  make install     - Install Node.js dependencies"
	@echo "  make producer    - Run producer (sends 100 messages)"
	@echo "  make consumer    - Run consumer (listens for messages)"

up:
	docker-compose up -d
	@echo "Waiting for Redpanda to be healthy..."
	@sleep 15
	@echo "Redpanda is ready!"
	@echo "Redpanda Console: http://localhost:8080"
	@echo "Kafka API: localhost:19092"
	@echo "Schema Registry: localhost:18081"
	@echo "REST API: localhost:18082"

down:
	docker-compose down

restart:
	docker-compose restart

logs:
	docker-compose logs -f

clean:
	docker-compose down -v
	@echo "All volumes removed"

status:
	@echo "Service Status:"
	@docker-compose ps
	@echo ""
	@echo "Cluster Health:"
	@docker exec redpanda rpk cluster health || echo "Redpanda not ready"

cluster-info:
	@echo "Cluster Information:"
	@docker exec redpanda rpk cluster info

install:
	npm install
	@echo "Dependencies installed successfully"

producer:
	@echo "Starting producer (will send 100 messages)..."
	node producer.js

consumer:
	@echo "Starting consumer (press Ctrl+C to stop)..."
	node consumer.js

console:
	@echo "Opening Redpanda Console..."
	@open http://localhost:8080 || xdg-open http://localhost:8080 || echo "Please open http://localhost:8080 in your browser"

topics:
	docker exec redpanda rpk topic list

create-topic:
	@if [ -z "$(TOPIC)" ]; then \
		echo "Error: TOPIC parameter is required"; \
		echo "Usage: make create-topic TOPIC=my-topic"; \
		exit 1; \
	fi
	docker exec redpanda rpk topic create $(TOPIC) --partitions 3
	@echo "Topic '$(TOPIC)' created successfully"

list-topics:
	@echo "Available topics:"
	@docker exec redpanda rpk topic list
