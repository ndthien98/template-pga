#!/bin/bash

# Script to run multiple consumers for testing rebalancing

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Starting 3 Consumers for Rebalancing Test                ║"
echo "║  Press Ctrl+C to stop all consumers                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Array to store PIDs
pids=()

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Stopping all consumers..."
    for pid in "${pids[@]}"; do
        kill -SIGINT $pid 2>/dev/null
    done
    wait
    echo "All consumers stopped"
    exit 0
}

# Trap Ctrl+C
trap cleanup SIGINT SIGTERM

# Start 3 consumers with different IDs
CONSUMER_ID="consumer-1" node consumer.js &
pids+=($!)
sleep 2

CONSUMER_ID="consumer-2" node consumer.js &
pids+=($!)
sleep 2

CONSUMER_ID="consumer-3" node consumer.js &
pids+=($!)

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  All 3 consumers started!                                 ║"
echo "║  Consumer PIDs: ${pids[@]}                                 "
echo "║  Press Ctrl+C to stop all consumers                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Wait for all background processes
wait
