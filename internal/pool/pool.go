package pool

import (
	"context"
	"fmt"
	"hash/fnv"
	"sync"
	"time"

	"go.uber.org/zap"

	"github.com/sparkiss/pos-cdc/internal/models"
	"github.com/sparkiss/pos-cdc/internal/processor"
	"github.com/sparkiss/pos-cdc/internal/writer"
	"github.com/sparkiss/pos-cdc/pkg/logger"
)

// Worker represents a single worker with its own queue
type Worker struct {
	id        int
	queue     chan *models.CDCEvent
	batchSize int
	processor *processor.Processor
	writer    writer.Writer
	dlq       *DLQ
	wg        *sync.WaitGroup
}

// WorkerPool manages concurrent event processing
type WorkerPool struct {
	workers   []*Worker
	batchSize int
	processor *processor.Processor
	writer    writer.Writer
	dlq       *DLQ
	wg        sync.WaitGroup
}

// New creates a new WorkerPool with a database writer.
// The writer can be MySQL or PostgreSQL (any type implementing writer.Writer).
func New(numWorkers, batchSize int, proc *processor.Processor, w writer.Writer) *WorkerPool {
	wp := &WorkerPool{
		workers:   make([]*Worker, numWorkers),
		batchSize: batchSize,
		processor: proc,
		writer:    w,
		dlq:       NewDLQ(),
	}

	for i := range numWorkers {
		wp.workers[i] = &Worker{
			id:        i,
			queue:     make(chan *models.CDCEvent, batchSize*2),
			batchSize: batchSize,
			processor: proc,
			writer:    w,
			dlq:       wp.dlq,
			wg:        &wp.wg,
		}
	}
	return wp
}

// Start launches worker goroutines
func (wp *WorkerPool) Start(ctx context.Context) {
	for _, worker := range wp.workers {
		wp.wg.Add(1)
		go worker.run(ctx)
	}
	logger.Log.Info("Worker pool started",
		zap.Int("workers", len(wp.workers)),
		zap.Int("batch_size", wp.batchSize))
}

// Submit routes event to worker based on topic+partition hash
func (wp *WorkerPool) Submit(event *models.CDCEvent) {
	// Topic-aware routing: same topic+partition always goes to same worker
	// This handles the case where all topics have partition 0
	key := fmt.Sprintf("%s:%d", event.Topic, event.Partition)
	workerIdx := int(fnv32(key)) % len(wp.workers)
	wp.workers[workerIdx].queue <- event
}

func fnv32(key string) uint32 {
	h := fnv.New32a()
	_, _ = h.Write([]byte(key)) // hash.Write never returns an error
	return h.Sum32()
}

func (wp *WorkerPool) Stop() {
	for _, worker := range wp.workers {
		close(worker.queue)
	}
	wp.wg.Wait()
	logger.Log.Info("Worker pool stopped")
}

func (w *Worker) run(ctx context.Context) {
	defer w.wg.Done()

	batch := make([]*models.CDCEvent, 0, w.batchSize)
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case event, ok := <-w.queue:
			if !ok {
				// Channel closed, process remaining batch
				if len(batch) > 0 {
					w.processBatch(batch)
				}
				return
			}

			batch = append(batch, event)
			if len(batch) >= w.batchSize {
				w.processBatch(batch)
				batch = batch[:0]
			}

		case <-ticker.C:
			// Flush incomplete batches after timeout
			if len(batch) > 0 {
				w.processBatch(batch)
				batch = batch[:0]
			}

		case <-ctx.Done():
			// Process remaining batch before exit
			if len(batch) > 0 {
				w.processBatch(batch)
			}
			return
		}
	}
}

func (w *Worker) processBatch(events []*models.CDCEvent) {
	queries := make([]writer.Query, 0, len(events))

	for _, event := range events {
		sql, args, err := w.processor.BuildSQL(event)
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

	if err := w.writer.ExecuteBatch(queries); err != nil {
		logger.Log.Error("Batch processing failed",
			zap.Int("worker", w.id),
			zap.Int("batch_size", len(queries)),
			zap.Error(err))

		// Send failed events to DLQ
		for _, event := range events {
			w.dlq.Send(event, err)
		}
		return
	}

	logger.Log.Debug("Batch processed",
		zap.Int("worker", w.id),
		zap.Int("count", len(queries)))
}
