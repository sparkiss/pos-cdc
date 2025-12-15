package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"go.uber.org/zap"

	//"github.com/IBM/sarama"
	"github.com/sparkiss/pos-cdc/internal/config"
	"github.com/sparkiss/pos-cdc/internal/consumer"
	"github.com/sparkiss/pos-cdc/internal/health"
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
		zap.String("target_type", string(cfg.TargetType)),
		zap.String("source_tz", cfg.SourceTimezone),
		zap.String("target_tz", cfg.TargetTimezone))

	healthServer := health.New(cfg.HealthPort)

	go func() {
		if err := healthServer.Start(); err != nil && err != http.ErrServerClosed {
			logger.Log.Error("Health server error", zap.Error(err))
		}
	}()

	// Create database writer based on target type
	var dbWriter writer.Writer
	if cfg.TargetType == config.TargetPostgres {
		dbWriter, err = writer.NewPostgres(cfg)
		if err != nil {
			logger.Log.Fatal("Failed to connect to PostgreSQL", zap.Error(err))
		}
		healthServer.UpdateCheck("postgres", health.CheckResult{
			Healthy: true,
			Message: "Connected",
		})
	} else {
		dbWriter, err = writer.NewMySQL(cfg)
		if err != nil {
			logger.Log.Fatal("Failed to connect to MySQL", zap.Error(err))
		}
		healthServer.UpdateCheck("mysql", health.CheckResult{
			Healthy: true,
			Message: "Connected",
		})
	}
	defer func() { _ = dbWriter.Close() }()

	schemaCache := schema.New(dbWriter.DB(), cfg.TargetDatabase(), cfg.TargetType)
	proc := processor.New(schemaCache, cfg.SourceLocation, cfg.TargetLocation, cfg.TargetType)

	// Create worker pool
	workerPool := pool.New(cfg.WorkerCount, cfg.BatchSize, proc, dbWriter)

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
	defer func() { _ = kafkaConsumer.Close() }()

	healthServer.UpdateCheck("kafka", health.CheckResult{
		Healthy: true,
		Message: "Connected",
	})

	/*
		healthServer.SetReady(true)
		// Start consumer in Background
		go func() {
			if err := kafkaConsumer.Start(ctx); err != nil {
				logger.Log.Error("Consumer stopped", zap.Error(err))
			}
		}()

		logger.Log.Info("CDCConsuemr running. Press Ctrl+C to stop")

		// Handle shutdown signals (Ctrl+C)
		sigterm := make(chan os.Signal, 1)
		signal.Notify(sigterm, syscall.SIGINT, syscall.SIGTERM)
		<-sigterm

		logger.Log.Info("Shutdown signal received")

		// Cancel context to stop consumer
		cancel()

		// Stop worker pool (drain queue and wait for workers)
		workerPool.Stop()

		// Stop health server
		if err := healthServer.Stop(); err != nil {
			logger.Log.Error("Health server shutdown error", zap.Error(err))
		}

		logger.Log.Info("CDC Consumer stopped")
	*/

	// Mark as ready
	healthServer.SetReady(true)

	// Context for graceful shutdown
	//ctx, cancel := context.WithCancel(context.Background())

	// WaitGroup for clean shutdown
	var wg sync.WaitGroup

	// Start consumer
	wg.Go(func() {
		if err := kafkaConsumer.Start(ctx); err != nil && err != context.Canceled {
			logger.Log.Error("Consumer error", zap.Error(err))
		}
	})

	logger.Log.Info("CDC Consumer running",
		zap.Int("health_port", cfg.HealthPort),
		zap.Int("metrics_port", cfg.MetricsPort))

	// Wait for shutdown signal
	sigterm := make(chan os.Signal, 1)
	signal.Notify(sigterm, syscall.SIGINT, syscall.SIGTERM)
	<-sigterm

	logger.Log.Info("Shutdown signal received, draining...")

	// Mark as not ready (stop accepting new work)
	healthServer.SetReady(false)

	// Cancel context (tells consumer to stop)
	cancel()

	// Wait for consumer to finish with timeout
	done := make(chan struct{})
	go func() {
		wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		logger.Log.Info("Consumer stopped gracefully")
	case <-time.After(30 * time.Second):
		logger.Log.Warn("Shutdown timeout, forcing exit")
	}

	// Stop worker pool (drain queues and wait for workers)
	workerPool.Stop()

	// Stop health server
	if err := healthServer.Stop(); err != nil {
		logger.Log.Error("Health server shutdown error", zap.Error(err))
	}

	logger.Log.Info("CDC Consumer stopped")

}
