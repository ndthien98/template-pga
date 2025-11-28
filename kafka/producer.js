const { Kafka } = require('kafkajs');

// Configure Redpanda client (Kafka-compatible)
const kafka = new Kafka({
  clientId: 'my-producer',
  brokers: ['localhost:19092'], // Redpanda external port
  retry: {
    initialRetryTime: 100,
    retries: 8
  }
});

const producer = kafka.producer();

const TOPIC = 'test-topic';

async function produceMessages() {
  try {
    // Connect to Redpanda
    await producer.connect();
    console.log('Producer connected to Redpanda successfully');

    // Send messages in a loop
    let messageCount = 0;
    const interval = setInterval(async () => {
      try {
        const message = {
          key: `key-${messageCount}`,
          value: JSON.stringify({
            id: messageCount,
            timestamp: new Date().toISOString(),
            data: `Message number ${messageCount}`,
            randomValue: Math.random() * 100
          })
        };

        await producer.send({
          topic: TOPIC,
          messages: [message]
        });

        console.log(`Message sent: ${messageCount} - ${message.value}`);
        messageCount++;

        // Stop after 100 messages
        if (messageCount >= 100) {
          clearInterval(interval);
          await shutdown();
        }
      } catch (error) {
        console.error('Error sending message:', error);
      }
    }, 1000); // Send a message every second

  } catch (error) {
    console.error('Error connecting producer:', error);
    await shutdown();
  }
}

async function shutdown() {
  try {
    console.log('\nShutting down producer...');
    await producer.disconnect();
    console.log('Producer disconnected successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error during shutdown:', error);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

// Start producing messages
produceMessages().catch(console.error);
