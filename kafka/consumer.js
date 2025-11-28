const { Kafka } = require('kafkajs');

// Get consumer ID from command line or generate one
const CONSUMER_ID = process.env.CONSUMER_ID || `consumer-${Math.floor(Math.random() * 1000)}`;

// Configure Redpanda client (Kafka-compatible)
const kafka = new Kafka({
  clientId: CONSUMER_ID,
  brokers: ['localhost:19092'], // Redpanda external port
  retry: {
    initialRetryTime: 100,
    retries: 8
  },
  logLevel: 2 // INFO level
});

const consumer = kafka.consumer({
  groupId: 'test-group',
  sessionTimeout: 30000,
  heartbeatInterval: 3000
});

const TOPIC = 'test-topic';

// Track assigned partitions
let assignedPartitions = [];

async function consumeMessages() {
  try {
    // Connect to Redpanda
    console.log(`\n${'='.repeat(60)}`);
    console.log(`[${CONSUMER_ID}] Connecting to Redpanda...`);
    console.log(`${'='.repeat(60)}\n`);

    await consumer.connect();
    console.log(`✓ [${CONSUMER_ID}] Connected to Redpanda successfully\n`);

    // Subscribe to consumer events for rebalancing
    consumer.on(consumer.events.GROUP_JOIN, (event) => {
      console.log(`\n${'*'.repeat(60)}`);
      console.log(`🔵 [${CONSUMER_ID}] GROUP JOIN EVENT`);
      console.log(`   Duration: ${event.payload.duration}ms`);
      console.log(`   Group ID: ${event.payload.groupId}`);
      console.log(`   Member ID: ${event.payload.memberId}`);
      console.log(`   Leader ID: ${event.payload.leaderId}`);
      console.log(`   IsLeader: ${event.payload.isLeader}`);
      console.log(`   Group Protocol: ${event.payload.groupProtocol}`);
      console.log(`${'*'.repeat(60)}\n`);
    });

    consumer.on(consumer.events.REBALANCING, (event) => {
      console.log(`\n${'!'.repeat(60)}`);
      console.log(`🟡 [${CONSUMER_ID}] REBALANCING STARTED`);
      console.log(`   Group ID: ${event.payload.groupId}`);
      console.log(`   Member ID: ${event.payload.memberId}`);
      console.log(`${'!'.repeat(60)}\n`);
    });

    consumer.on(consumer.events.CONNECT, () => {
      console.log(`✓ [${CONSUMER_ID}] Consumer CONNECT event\n`);
    });

    consumer.on(consumer.events.DISCONNECT, () => {
      console.log(`✗ [${CONSUMER_ID}] Consumer DISCONNECT event\n`);
    });

    consumer.on(consumer.events.CRASH, (event) => {
      console.error(`\n💥 [${CONSUMER_ID}] CRASH event:`, event.payload.error);
    });

    // Subscribe to topic
    console.log(`[${CONSUMER_ID}] Subscribing to topic: ${TOPIC}...`);
    await consumer.subscribe({
      topic: TOPIC,
      fromBeginning: true
    });
    console.log(`✓ [${CONSUMER_ID}] Subscribed to topic: ${TOPIC}\n`);

    // Start consuming messages
    await consumer.run({
      partitionsConsumedConcurrently: 3,
      eachMessage: async ({ topic, partition, message }) => {
        try {
          const key = message.key ? message.key.toString() : null;
          const value = message.value.toString();
          const parsedValue = JSON.parse(value);

          console.log(`\n--- [${CONSUMER_ID}] Message Received ---`);
          console.log(`Topic: ${topic}`);
          console.log(`Partition: ${partition}`);
          console.log(`Offset: ${message.offset}`);
          console.log(`Key: ${key}`);
          console.log(`Value ID: ${parsedValue.id}`);
          console.log(`-----------------------------------\n`);
        } catch (error) {
          console.error(`[${CONSUMER_ID}] Error processing message:`, error);
        }
      },
      eachBatchAutoResolve: true,
      eachBatch: async ({ batch, resolveOffset, heartbeat, commitOffsetsIfNecessary, isRunning, isStale }) => {
        // Log batch assignment
        const partition = batch.partition;
        if (!assignedPartitions.includes(partition)) {
          assignedPartitions.push(partition);
          assignedPartitions.sort((a, b) => a - b);

          console.log(`\n${'▶'.repeat(60)}`);
          console.log(`🟢 [${CONSUMER_ID}] PARTITION ASSIGNED`);
          console.log(`   Topic: ${batch.topic}`);
          console.log(`   Partition: ${partition}`);
          console.log(`   Current Assigned Partitions: [${assignedPartitions.join(', ')}]`);
          console.log(`   High Water Mark: ${batch.highWatermark}`);
          console.log(`   Messages in Batch: ${batch.messages.length}`);
          console.log(`${'▶'.repeat(60)}\n`);
        }

        for (let message of batch.messages) {
          if (!isRunning() || isStale()) break;

          try {
            const key = message.key ? message.key.toString() : null;
            const value = message.value.toString();
            const parsedValue = JSON.parse(value);

            console.log(`[${CONSUMER_ID}] P${partition} → Msg#${parsedValue.id}`);

            resolveOffset(message.offset);
            await heartbeat();
          } catch (error) {
            console.error(`[${CONSUMER_ID}] Error in batch:`, error);
          }
        }

        await commitOffsetsIfNecessary();
      }
    });

  } catch (error) {
    console.error('Error in consumer:', error);
    await shutdown();
  }
}

async function shutdown() {
  try {
    console.log(`\n${'='.repeat(60)}`);
    console.log(`[${CONSUMER_ID}] Shutting down consumer...`);
    console.log(`   Assigned Partitions: [${assignedPartitions.join(', ')}]`);
    console.log(`${'='.repeat(60)}\n`);

    await consumer.disconnect();
    console.log(`✓ [${CONSUMER_ID}] Consumer disconnected successfully\n`);
    process.exit(0);
  } catch (error) {
    console.error(`[${CONSUMER_ID}] Error during shutdown:`, error);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

// Log startup
console.log(`\n╔${'═'.repeat(58)}╗`);
console.log(`║  Consumer Starting: ${CONSUMER_ID.padEnd(36)} ║`);
console.log(`║  Group: test-group${' '.repeat(36)}║`);
console.log(`║  Topic: ${TOPIC.padEnd(48)}║`);
console.log(`╚${'═'.repeat(58)}╝\n`);

// Start consuming messages
consumeMessages().catch(console.error);
