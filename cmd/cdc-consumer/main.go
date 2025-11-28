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
	"github.com/sparkiss/pos-cdc/internal/processor"
	"github.com/sparkiss/pos-cdc/internal/writer"
)

func main() {
	fmt.Println("CDC Consumer starting...")

	//FIXME: Hardcoded values -- extract it in config
	brokers := []string{"localhost:9092"}
	groupID := "cdc-consumer-group"

	mysqlWriter, err := writer.New(writer.Config{
		Host:       "localhost",
		Port:       3307,
		User:       "cdc_writer",
		Password:   "fixme", //FIXME: from env
		Database:   "pos_replica",
		MaxRetries: 3,
		BackoffMS:  1000,
	})
	if err != nil {
		log.Fatalf("Failed to connect to MySQL: %v", err)
	}
	defer mysqlWriter.Close()

	proc := processor.New()

	// Create event handler
	handler := func(event *models.CDCEvent) error {
		sql, args, err := proc.BuildSQL(event)
		if err != nil {
			return fmt.Errorf("failed to build SQL: %w", err)
		}

		if err := mysqlWriter.Execute(sql, args); err != nil {
			return fmt.Errorf("failed to execute: %w", err)
		}
		log.Printf("Applied: table=%s op=%s",
			event.SourceTable,
			event.GetOperation().String())
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
