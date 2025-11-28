#!/bin/bash

cd /Users/thomas/Desktop/ndthien98-github/template-pga/kafka

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║              CONSUMER GROUP REBALANCING ANALYSIS                   ║"
echo "║              Topic: test-topic (3 partitions)                      ║"
echo "║              Consumer Group: test-group (6 consumers)              ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

echo "🔄 REBALANCING TIMELINE:"
echo "─────────────────────────────────────────────────────────────────────"
echo "Consumer 1 starts   → Gets all 3 partitions [0, 1, 2]"
echo "Consumer 2 joins    → REBALANCE → Each gets ~1.5 partitions"
echo "Consumer 3 joins    → REBALANCE → Each gets 1 partition"
echo "Consumer 4 joins    → REBALANCE → 3 active, 1 idle"
echo "Consumer 5 joins    → REBALANCE → 3 active, 2 idle"
echo "Consumer 6 joins    → REBALANCE → 3 active, 3 idle"
echo ""

echo "📊 REBALANCING EVENT COUNT PER CONSUMER:"
echo "─────────────────────────────────────────"
for i in 1 2 3 4 5 6; do
  count=$(grep -c "REBALANCING STARTED" consumer${i}.log 2>/dev/null || echo "0")
  joins=$(grep -c "GROUP JOIN EVENT" consumer${i}.log 2>/dev/null || echo "0")
  echo "Consumer $i: $count rebalancing events, $joins group joins"
done

echo ""
echo "👥 LEADERSHIP INFORMATION:"
echo "─────────────────────────────────────────"
for i in 1 2 3 4 5 6; do
  is_leader=$(grep "IsLeader: true" consumer${i}.log 2>/dev/null | wc -l)
  if [ "$is_leader" -gt 0 ]; then
    echo "Consumer $i: GROUP LEADER ⭐ (makes partition assignment decisions)"
  else
    echo "Consumer $i: Group member (follows leader's assignment)"
  fi
done

echo ""
echo "📨 MESSAGE DISTRIBUTION:"
echo "─────────────────────────"
for i in 1 2 3 4 5 6; do
  msg_count=$(grep -c "Message Received" consumer${i}.log 2>/dev/null || echo "0")
  batch_msg=$(grep -c "P[0-9] → Msg#" consumer${i}.log 2>/dev/null || echo "0")
  total=$((msg_count + batch_msg))

  if [ "$total" -gt 0 ]; then
    echo "Consumer $i: $total messages processed ✓"
  else
    echo "Consumer $i: 0 messages processed (IDLE)"
  fi
done

echo ""
echo "🎯 PARTITION ASSIGNMENTS (Final State):"
echo "────────────────────────────────────────"
for i in 1 2 3 4 5 6; do
  partitions=$(grep "Current Assigned Partitions" consumer${i}.log 2>/dev/null | tail -1 | grep -o "\[.*\]")
  if [ "$partitions" != "" ] && [ "$partitions" != "[]" ]; then
    echo "Consumer $i → Partitions: $partitions (ACTIVE)"
  else
    echo "Consumer $i → Partitions: [] (IDLE - waiting for rebalance)"
  fi
done

echo ""
echo "📋 DETAILED REBALANCING LOG (Consumer 1 - Leader):"
echo "────────────────────────────────────────────────────"
grep -E "(Consumer Starting|🔵.*GROUP JOIN|🟡.*REBALANCING)" consumer1.log | head -20

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "KEY INSIGHTS:"
echo "═══════════════════════════════════════════════════════════════════"
echo "✓ With 3 partitions and 6 consumers:"
echo "  - Only 3 consumers can be active (1 partition each)"
echo "  - 3 consumers remain idle (no partitions assigned)"
echo "✓ Each new consumer joining triggers a rebalance"
echo "✓ Consumer 1 is the group leader (coordinates assignments)"
echo "✓ RoundRobinAssigner distributes partitions evenly"
echo "═══════════════════════════════════════════════════════════════════"
