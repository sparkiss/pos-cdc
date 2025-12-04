package pool

import (
	"context"
	"sync"
	"time"

	"go.uber.org/zap"

	"github.com/sparkiss/pos-cdc/internal/models"
	"github.com/sparkiss/pos-cdc/internal/processor"
	"github.com/sparkiss/pos-cdc/internal/writer"
	"github.com/sparkiss/pos-cdc/pkg/logger"
)

// WorkerPool manages concurrent event processing
type WorkerPool struct {
	workers   int
	batchSize int
	queue     chan *models.CDCEvent
	processor *processor.Processor
	writer    *writer.MySQLWriter
	dlq       *DLQ
	wg        sync.WaitGroup
}

// New creates a new WorkerPool
func New(workers, batchSize int, proc *processor.Processor, w *writer.MySQLWriter) *WorkerPool {
	return &WorkerPool{
		workers:   workers,
		batchSize: batchSize,
		queue:     make(chan *models.CDCEvent, batchSize*workers),
		processor: proc,
		writer:    w,
		dlq:       NewDLQ(),
	}
}

// Start launches worker goroutines
func (wp *WorkerPool) Start(ctx context.Context) {
	for i := 0; i < wp.workers; i++ {
		wp.wg.Add(1)
		go wp.worker(ctx, i)
	}
	logger.Log.Info("Worker pool started",
		zap.Int("workers", wp.workers),
		zap.Int("batch_size", wp.batchSize))
}

// Submit adds an event to the processing queue
func (wp *WorkerPool) Submit(event *models.CDCEvent) {
	wp.queue <- event
}

// Stop waits for all workers to finish
func (wp *WorkerPool) Stop() {
	close(wp.queue)
	wp.wg.Wait()
	logger.Log.Info("Worker pool stopped")
}

func (wp *WorkerPool) worker(ctx context.Context, id int) {
	defer wp.wg.Done()

	batch := make([]*models.CDCEvent, 0, wp.batchSize)
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case event, ok := <-wp.queue:
			if !ok {
				// Channel closed, process remaining batch
				if len(batch) > 0 {
					wp.processBatch(batch, id)
				}
				return
			}

			batch = append(batch, event)
			if len(batch) >= wp.batchSize {
				wp.processBatch(batch, id)
				batch = batch[:0] // Reset slice, keep capacity
			}

		case <-ticker.C:
			// Flush incomplete batches after timeout
			if len(batch) > 0 {
				wp.processBatch(batch, id)
				batch = batch[:0]
			}

		case <-ctx.Done():
			// Process remaining batch before exit
			if len(batch) > 0 {
				wp.processBatch(batch, id)
			}
			return
		}
	}
}

func (wp *WorkerPool) processBatch(events []*models.CDCEvent, workerID int) {
	queries := make([]writer.Query, 0, len(events))

	for _, event := range events {
		sql, args, err := wp.processor.BuildSQL(event)
		if err != nil {
			logger.Log.Debug("Skipping event in batch",
				zap.String("table", event.SourceTable),
				zap.Error(err))
			continue
		}

		queries = append(queries, writer.Query{
			SQL:   sql,
			Args:  args,
			Table: event.SourceTable,
			Op:    event.GetOperation().String(),
		})
	}

	if len(queries) == 0 {
		return
	}

	if err := wp.writer.ExecuteBatch(queries); err != nil {
		logger.Log.Error("Batch processing failed",
			zap.Int("worker", workerID),
			zap.Int("batch_size", len(queries)),
			zap.Error(err))

		// Send failed events to DLQ
		for _, event := range events {
			wp.dlq.Send(event, err)
		}
		return
	}

	logger.Log.Info("Batch processed",
		zap.Int("worker", workerID),
		zap.Int("count", len(queries)))
}
