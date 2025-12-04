package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"go.uber.org/zap"

	//"github.com/IBM/sarama"
	"github.com/sparkiss/pos-cdc/internal/config"
	"github.com/sparkiss/pos-cdc/internal/consumer"
	"github.com/sparkiss/pos-cdc/internal/models"
	"github.com/sparkiss/pos-cdc/internal/pool"
	"github.com/sparkiss/pos-cdc/internal/processor"
	"github.com/sparkiss/pos-cdc/internal/schema"
	"github.com/sparkiss/pos-cdc/internal/writer"
	"github.com/sparkiss/pos-cdc/pkg/logger"
)

func main() {

	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to load config: %v\n", err)
		os.Exit(1)
	}

	if err := logger.Init(cfg.LogLevel, cfg.LogFormat); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to init logger: %v\n", err)
		os.Exit(1)
	}
	defer logger.Sync()

	logger.Log.Info("CDC Consumer starting",
		zap.String("log_level", cfg.LogLevel),
		zap.String("source_tz", cfg.SourceTimezone),
		zap.String("target_tz", cfg.TargetTimezone))

	mysqlWriter, err := writer.New(cfg)
	if err != nil {
		logger.Log.Fatal("Failed to connect to MySQL: %v", zap.Error(err))
	}
	defer mysqlWriter.Close()

	schemaCache := schema.New(mysqlWriter.DB(), cfg.TargetDB.Database)

	proc := processor.New(schemaCache, cfg.SourceLocation, cfg.TargetLocation)

	// Create worker pool
	workerPool := pool.New(cfg.WorkerCount, cfg.BatchSize, proc, mysqlWriter)

	// Create context with cancellation
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	workerPool.Start(ctx)

	handler := func(event *models.CDCEvent) error {
		workerPool.Submit(event)
		return nil
	}
	kafkaConsumer, err := consumer.New(cfg, handler)
	if err != nil {
		logger.Log.Fatal("Failed to create consumer", zap.Error(err))
	}
	defer kafkaConsumer.Close()

	// Handle shutdown signals (Ctrl+C)
	sigterm := make(chan os.Signal, 1)
	signal.Notify(sigterm, syscall.SIGINT, syscall.SIGTERM)

	// Start consumer in Background
	go func() {
		if err := kafkaConsumer.Start(ctx); err != nil {
			logger.Log.Error("Consumer stopped", zap.Error(err))
		}
	}()

	logger.Log.Info("CDCConsuemr running. Press Ctrl+C to stop")

	// Wait for shutdown signal
	<-sigterm
	logger.Log.Info("Shutdown signal received")

	// Cancel context to stop consumer
	cancel()

	logger.Log.Info("CDC Consumer stopped")
}
