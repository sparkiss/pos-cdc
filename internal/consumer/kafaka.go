package consumer

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	//"maps"
	//"slices"
	"strings"

	"github.com/IBM/sarama"
	"github.com/sparkiss/pos-cdc/internal/models"
)

// ======================================================
// ==== Consumer - a wrapper for Kafa consumer group  ===
// ======================================================
type Consumer struct {
	client       sarama.ConsumerGroup
	brokers      []string
	groupID      string
	eventHandler func(*models.CDCEvent) error
}

// FIXME: All these parameters should come from config
func New(brokers []string, groupID string, handler func(*models.CDCEvent) error) (*Consumer, error) {
	config := sarama.NewConfig()
	config.Version = sarama.V2_8_0_0

	config.Consumer.Group.Rebalance.Strategy = sarama.NewBalanceStrategyRoundRobin()
	config.Consumer.Offsets.Initial = sarama.OffsetOldest

	//TODO: Make this configurable
	//config.Consumer.Offsets.Initial = sarama.OffsetNewest
	//
	client, err := sarama.NewConsumerGroup(brokers, groupID, config)
	if err != nil {
		return nil, fmt.Errorf("failed to create consumer group: %w", err)
	}

	return &Consumer{
		client:       client,
		brokers:      brokers,
		groupID:      groupID,
		eventHandler: handler,
	}, nil
}

func (c *Consumer) Start(ctx context.Context) error {
	// Get list of CDC topics dynamically
	topics, err := c.getTopics()
	if err != nil {
		return fmt.Errorf("failed to get topic: %w", err)
	}

	log.Printf("Subscribing to %d topics", len(topics))
	for _, t := range topics {
		log.Printf(" - %s", t)
	}

	handler := &consumerGroupHandler{
		consumer: c,
	}

	for {
		err := c.client.Consume(ctx, topics, handler)
		if err != nil {
			log.Printf("Consumer error : %v", err)
			return err
		}

		if ctx.Err() != nil {
			log.Println("Context cancelled, stopping consumer")
			return ctx.Err()
		}

		log.Println("Rabalance occurred, restarting consumer...")
	}
}

func (c *Consumer) getTopics() ([]string, error) {
	admin, err := sarama.NewClusterAdmin(c.brokers, sarama.NewConfig())
	if err != nil {
		return nil, err
	}
	defer admin.Close()

	allTopics, err := admin.ListTopics()
	if err != nil {
		return nil, err
	}

	var cdcTopics []string
	for topic := range allTopics {
		if strings.HasPrefix(topic, "pos_mysql.pos.") {
			cdcTopics = append(cdcTopics, topic)
		}
	}

	return cdcTopics, nil

}

func (c *Consumer) Close() error {
	return c.client.Close()

}

// ======================================================
// ==== consumerGroupHandler - implements sarama.consumerGroupHandler
// ======================================================
type consumerGroupHandler struct {
	consumer *Consumer
}

// Setup is called a t the beginniong of a new session
func (h *consumerGroupHandler) Setup(session sarama.ConsumerGroupSession) error {
	log.Printf("Consumer session started. Claims: %v", session.Claims())
	return nil
}

// Cleanup is called at the end of session
func (h *consumerGroupHandler) Cleanup(session sarama.ConsumerGroupSession) error {
	log.Printf("Consumer session ended")
	return nil
}

func (h *consumerGroupHandler) ConsumeClaim(session sarama.ConsumerGroupSession, claim sarama.ConsumerGroupClaim) error {
	for message := range claim.Messages() {
		event, err := h.parseEvent(message)
		if err != nil {
			log.Printf("Failed to parse event: %v (topic=%s, offset=%d)",
				err, message.Topic, message.Offset)
			// Mark as processed even if parsing fails
			// TODO: Consider sending to dead leatter queue instead
			session.MarkMessage(message, "")
			continue
		}

		parts := strings.Split(message.Topic, ".")
		if len(parts) >= 3 {
			event.SourceTable = parts[2]
		}

		log.Printf("Event: table=%s op=%s",
			event.SourceTable,
			event.GetOperation().String())

		// Call the handler
		if err := h.consumer.eventHandler(event); err != nil {
			log.Printf("Handler failed: %v", err)
			// Do not mark as processed - will retry on next consume
			// FIXME: Need bettery retry logic
			continue
		}
		session.MarkMessage(message, "")
	}
	return nil
}

// parseEvent converts a Kafka message to a CDCEvent
func (h *consumerGroupHandler) parseEvent(msg *sarama.ConsumerMessage) (*models.CDCEvent, error) {
	if msg.Value == nil {
		return &models.CDCEvent{
			Operation: "d",
			Deleted:   "true",
		}, nil
	}

	// Parse JSON payload
	var payload map[string]any
	if err := json.Unmarshal(msg.Value, &payload); err != nil {
		return nil, fmt.Errorf("failed to unmarsharl: %w", err)
	}

	event := &models.CDCEvent{
		Payload: payload,
	}

	// Extract metadata fields (added by Debezium transform)
	if op, ok := payload["__op"].(string); ok {
		event.Operation = op
	}
	if ts, ok := payload["__ts_ms"].(float64); ok {
		event.Timestamp = int64(ts)
	}
	if db, ok := payload["__source_db"].(string); ok {
		event.SourceDB = db
	}
	if table, ok := payload["__source_table"].(string); ok {
		event.SourceTable = table
	}
	if deleted, ok := payload["__deleted"].(string); ok {
		event.Deleted = deleted
	}
	return event, nil

}
