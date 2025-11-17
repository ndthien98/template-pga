#!/bin/bash
set -e

# Wait for master to be ready
echo "Waiting for master database to be ready..."
until PGPASSWORD=postgres psql -h "pg-master" -U "postgres" -c '\q'; do
  echo "Master is unavailable - sleeping"
  sleep 1
done

echo "Master is up - checking if replica needs initialization"

# Check if this is a fresh replica that needs basebackup
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "Initializing replica from master..."

    # Remove any existing data
    rm -rf $PGDATA/*

    # Create base backup from master
    PGPASSWORD=postgres pg_basebackup -h pg-master -D $PGDATA -U postgres -v -P -W -R

    echo "Base backup completed"

    # The -R flag creates standby.signal and updates postgresql.auto.conf
    # But we'll ensure the connection info is correct
    cat >> $PGDATA/postgresql.auto.conf <<EOF
primary_conninfo = 'host=pg-master port=5432 user=postgres password=postgres application_name=$(hostname)'
EOF

    echo "Replica initialized successfully"
else
    echo "Replica already initialized, skipping basebackup"
fi
