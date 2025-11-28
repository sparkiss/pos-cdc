package models

import "time"

// from Debezium
type CDCEvent struct {
	Operation   string `json:"__op"`
	Timestamp   int64  `json:"__ts_ms"`
	SourceDB    string `json:"__source_db"`
	SourceTable string `json:"__source_table"`
	Deleted     string `json:"__deleted"`

	Payload map[string]any `json:"-"`
}

type Operation int

const (
	OperationUnknown Operation = iota
	OperationInsert
	OperationUpdate
	OperationDelete
)

func (e *CDCEvent) GetOperation() Operation {
	switch e.Operation {
	case "c", "r": //r=read is for initial snapshot
		return OperationInsert
	case "u":
		return OperationUpdate
	case "d":
		return OperationDelete
	default:
		return OperationUnknown
	}
}

func (e *CDCEvent) GetTime() time.Time {
	return time.UnixMilli(e.Timestamp)
}

func (o Operation) String() string {
	switch o {
	case OperationInsert:
		return "INSERT"
	case OperationUpdate:
		return "UPDATE"
	case OperationDelete:
		return "DELETE"
	default:
		return "UNKNOWN"
	}

}
