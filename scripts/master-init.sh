#!/bin/bash
set -e

# Create replication user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create replication user if not exists
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'replicator') THEN
            CREATE ROLE replicator WITH REPLICATION PASSWORD 'replicator_password' LOGIN;
        END IF;
    END
    \$\$;

    -- Create pg_stat_statements extension
    CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

    -- Create a table to store slow query logs in a structured way
    CREATE TABLE IF NOT EXISTS slow_query_log (
        id SERIAL PRIMARY KEY,
        query_text TEXT,
        execution_time_ms NUMERIC,
        calls BIGINT,
        mean_exec_time_ms NUMERIC,
        max_exec_time_ms NUMERIC,
        min_exec_time_ms NUMERIC,
        stddev_exec_time_ms NUMERIC,
        logged_at TIMESTAMP DEFAULT NOW()
    );

    -- Grant necessary permissions
    GRANT SELECT ON pg_stat_statements TO postgres;
    GRANT ALL ON slow_query_log TO postgres;
EOSQL

echo "Master database initialized successfully"
