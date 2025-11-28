package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	//"github.com/IBM/sarama"
	"github.com/sparkiss/pos-cdc/internal/consumer"
	"github.com/sparkiss/pos-cdc/internal/models"
)

func main() {
	fmt.Println("CDC Consumer starting...")

	//FIXME: Hardcoded values -- extract it in config
	brokers := []string{"localhost:9092"}
	groupID := "cdc-consumer-group"

	// Create event handler
	// For now, just print events
	// TODO: change it to databse instead
	handler := func(event *models.CDCEvent) error {
		log.Printf("Received: table=%s op=%s payload=%v",
			event.SourceTable,
			event.GetOperation().String(),
			event.Payload)
		return nil
	}

	kafkaConsumer, err := consumer.New(brokers, groupID, handler)
	if err != nil {
		log.Fatalf("Failed to create consumer: %v", err)
	}
	defer kafkaConsumer.Close()

	// Create context with cancellation
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Handle shutdown signals (Ctrl+C)
	sigterm := make(chan os.Signal, 1)
	signal.Notify(sigterm, syscall.SIGINT, syscall.SIGTERM)

	// Start consumer in Background
	go func() {
		if err := kafkaConsumer.Start(ctx); err != nil {
			log.Printf("Consumer stopped: %v", err)
		}
	}()

	log.Println("CDCConsuemr running. Press Ctrl+C to stop")

	// Wait for shutdown signal
	<-sigterm
	log.Println("Shutdown signal received")

	// Cancel context to stop consumer
	cancel()

	log.Println("CDC Consumer stopped")
}
