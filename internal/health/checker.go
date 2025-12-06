package health

import (
	"context"
	"time"

	"go.uber.org/zap"

	"github.com/sparkiss/pos-cdc/internal/consumer"
	"github.com/sparkiss/pos-cdc/internal/metrics"
	"github.com/sparkiss/pos-cdc/internal/writer"
	"github.com/sparkiss/pos-cdc/pkg/logger"
)

// Checker performs periodic health checks
type Checker struct {
	server   *Server
	mysql    *writer.MySQLWriter
	kafka    *consumer.Consumer
	interval time.Duration
}

// NewChecker creates a health checker
func NewChecker(server *Server, mysql *writer.MySQLWriter, kafka *consumer.Consumer, interval time.Duration) *Checker {
	return &Checker{
		server:   server,
		mysql:    mysql,
		kafka:    kafka,
		interval: interval,
	}
}

func (c *Checker) Start(ctx context.Context) {
	// Run immediately on start
	c.checkAll()

	ticker := time.NewTicker(c.interval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			c.checkAll()
		case <-ctx.Done():
			logger.Log.Info("Health checker stopped")
			return
		}
	}
}

func (c *Checker) checkAll() {
	c.checkMySQL()
	c.checkKafka()
	c.updateReadyStatus()
}

func (c *Checker) checkMySQL() {
	start := time.Now()
	err := c.mysql.Ping()
	duration := time.Since(start)

	if err != nil {
		logger.Log.Warn("MySQL health check failed",
			zap.Error(err),
			zap.Duration("duration", duration))

		c.server.UpdateCheck("mysql", CheckResult{
			Healthy: false,
			Message: err.Error(),
		})
		metrics.ConnectionStatus.WithLabelValues("mysql").Set(0)
	} else {
		c.server.UpdateCheck("mysql", CheckResult{
			Healthy: true,
			Message: "Connected",
		})
		metrics.ConnectionStatus.WithLabelValues("mysql").Set(1)
	}
}

func (c *Checker) checkKafka() {
	// Check if consumer is connected and consuming
	connected := c.kafka.IsConnected()

	if !connected {
		logger.Log.Warn("Kafka health check failed")

		c.server.UpdateCheck("kafka", CheckResult{
			Healthy: false,
			Message: "Disconnected",
		})
		metrics.ConnectionStatus.WithLabelValues("kafka").Set(0)
	} else {
		c.server.UpdateCheck("kafka", CheckResult{
			Healthy: true,
			Message: "Connected",
		})
		metrics.ConnectionStatus.WithLabelValues("kafka").Set(1)
	}
}

func (c *Checker) updateReadyStatus() {
	c.server.mu.RLock()
	defer c.server.mu.RUnlock()

	// Service is ready only if all checks pass
	allHealthy := true
	for _, check := range c.server.lastChecks {
		if !check.Healthy {
			allHealthy = false
			break
		}
	}

	c.server.mu.RUnlock()
	c.server.mu.Lock()
	c.server.ready = allHealthy
	c.server.mu.Unlock()
	c.server.mu.RLock()
}
