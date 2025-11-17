#!/bin/bash

echo "=========================================="
echo "PostgreSQL Master-Slave Monitoring Stack"
echo "=========================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

echo "Starting all services..."
docker-compose up -d

echo ""
echo "Waiting for services to initialize..."
sleep 15

echo ""
echo "Checking service health..."
echo ""

# Check PostgreSQL Master
if docker exec pg-master pg_isready -U postgres > /dev/null 2>&1; then
    echo "✓ PostgreSQL Master is ready (port 5432)"
else
    echo "✗ PostgreSQL Master is not ready"
fi

# Check PostgreSQL Replica 1
if docker exec pg-replica-1 pg_isready -U postgres > /dev/null 2>&1; then
    echo "✓ PostgreSQL Replica 1 is ready (port 5433)"
else
    echo "✗ PostgreSQL Replica 1 is not ready"
fi

# Check PostgreSQL Replica 2
if docker exec pg-replica-2 pg_isready -U postgres > /dev/null 2>&1; then
    echo "✓ PostgreSQL Replica 2 is ready (port 5434)"
else
    echo "✗ PostgreSQL Replica 2 is not ready"
fi

# Check Prometheus
if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
    echo "✓ Prometheus is ready (port 9090)"
else
    echo "✗ Prometheus is not ready"
fi

# Check Grafana
if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    echo "✓ Grafana is ready (port 3000)"
else
    echo "✗ Grafana is not ready"
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Access the services:"
echo "  • Grafana:    http://localhost:3000 (admin/admin)"
echo "  • Prometheus: http://localhost:9090"
echo ""
echo "Database connections:"
echo "  • Master:     localhost:5432"
echo "  • Replica 1:  localhost:5433"
echo "  • Replica 2:  localhost:5434"
echo ""
echo "Useful commands:"
echo "  • View logs:           docker-compose logs -f"
echo "  • Stop services:       docker-compose down"
echo "  • Restart services:    docker-compose restart"
echo "  • Check replication:   make status"
echo "  • Test replication:    make test-replication"
echo "  • Generate slow queries: make test-slow-query"
echo ""
echo "For more commands, run: make help"
echo ""
