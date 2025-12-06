package consumer

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"

	//"maps"
	//"slices"
	"strings"

	"go.uber.org/zap"

	"github.com/IBM/sarama"
	"github.com/sparkiss/pos-cdc/internal/config"
	"github.com/sparkiss/pos-cdc/internal/models"
	"github.com/sparkiss/pos-cdc/pkg/logger"
)

// ======================================================
// ==== Consumer - a wrapper for Kafa consumer group  ===
// ======================================================
type Consumer struct {
	config       *config.Config
	client       sarama.ConsumerGroup
	eventHandler func(*models.CDCEvent) error
	connected    bool
	mu           sync.RWMutex
}

func New(cfg *config.Config, handler func(*models.CDCEvent) error) (*Consumer, error) {
	saramaCfg := sarama.NewConfig()
	saramaCfg.Version = sarama.V2_8_0_0

	saramaCfg.Consumer.Group.Rebalance.Strategy = sarama.NewBalanceStrategyRoundRobin()
	if cfg.KafkaAutoOffsetReset == "latest" {
		saramaCfg.Consumer.Offsets.Initial = sarama.OffsetNewest
	} else {
		saramaCfg.Consumer.Offsets.Initial = sarama.OffsetOldest
	}

	client, err := sarama.NewConsumerGroup(cfg.KafkaBrokers, cfg.KafkaGroupID, saramaCfg)
	if err != nil {
		return nil, fmt.Errorf("failed to create consumer group: %w", err)
	}

	return &Consumer{
		config:       cfg,
		client:       client,
		eventHandler: handler,
	}, nil
}

func (c *Consumer) Start(ctx context.Context) error {
	// Get list of CDC topics dynamically
	topics, err := c.getTopics()
	if err != nil {
		return fmt.Errorf("failed to get topic: %w", err)
	}

	logger.Log.Info("Subscribing",
		zap.Int("topics", len(topics)))
	for _, t := range topics {
		logger.Log.Info("Topic List", zap.String("topic", t))
	}

	handler := &consumerGroupHandler{
		consumer: c,
	}

	for {
		err := c.client.Consume(ctx, topics, handler)
		if err != nil {
			logger.Log.Error("Consumer error", zap.Error(err))
			return err
		}

		if ctx.Err() != nil {
			logger.Log.Info("Context cancelled, stopping consumer")
			return ctx.Err()
		}

		logger.Log.Info("Rabalance occurred, restarting consumer...")
	}
}

func (c *Consumer) getTopics() ([]string, error) {
	admin, err := sarama.NewClusterAdmin(c.config.KafkaBrokers, sarama.NewConfig())
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

// IsConnected returns whether the consumer is connected to Kafka
func (c *Consumer) IsConnected() bool {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.connected
}

// setConnected updates connection status
func (c *Consumer) setConnected(status bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.connected = status
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
	h.consumer.setConnected(true)
	logger.Log.Info("Consumer session started", zap.Int32s("partitions", getPartitions(session.Claims())))
	return nil
}

func getPartitions(claims map[string][]int32) []int32 {
	var partitions []int32
	for _, parts := range claims {
		partitions = append(partitions, parts...)
	}
	return partitions
}

// Cleanup is called at the end of session
func (h *consumerGroupHandler) Cleanup(session sarama.ConsumerGroupSession) error {
	h.consumer.setConnected(false)
	logger.Log.Info("Consumer session ended")
	return nil
}

func (h *consumerGroupHandler) ConsumeClaim(session sarama.ConsumerGroupSession, claim sarama.ConsumerGroupClaim) error {
	for {
		select {
		case <-session.Context().Done():
			return nil
		case message, ok := <-claim.Messages():
			if !ok {
				return nil
			}

			event, err := h.parseEvent(message)
			if err != nil {
				logger.Log.Error("Failed to parse event", zap.Error(err),
					zap.String("topic", message.Topic),
					zap.Int64("offset", message.Offset))
				continue
			}

			parts := strings.Split(message.Topic, ".")
			if len(parts) >= 3 {
				event.SourceTable = parts[2]
			}

			logger.Log.Info("Event",
				zap.String("table", event.SourceTable),
				zap.String("op", event.GetOperation().String()))

			if err := h.consumer.eventHandler(event); err != nil {
				logger.Log.Error("Handler failed: %v", zap.Error(err))
				continue
			}
			session.MarkMessage(message, "")
		}
	}
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
