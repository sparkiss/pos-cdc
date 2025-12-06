package metrics

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	// EventsProcessed counts total events by table and operation
	EventsProcessed = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "cdc_events_processed_total",
			Help: "Total number of CDC events processed",
		},
		[]string{"table", "operation"},
	)

	// EventsFailed counts failed events
	EventsFailed = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "cdc_events_failed_total",
			Help: "Total number of CDC events that failed processing",
		},
		[]string{"table", "operation", "error_type"},
	)

	// QueryDuration measures database query time
	QueryDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "cdc_query_duration_seconds",
			Help:    "Duration of database queries in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"table", "operation"},
	)

	// ConsumerLag tracks Kafka consumer lag
	ConsumerLag = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "cdc_consumer_lag",
			Help: "Current consumer lag (messages behind)",
		},
		[]string{"topic", "partition"},
	)

	// ConnectionStatus tracks connection health
	ConnectionStatus = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "cdc_connection_status",
			Help: "Connection status (1=connected, 0=disconnected)",
		},
		[]string{"component"}, // "kafka", "mysql"
	)
)
