package repository

import (
	"context"
	"time"
)

// Estados de un trabajo asíncrono (§10.2, colección trabajos).
const (
	TrabajoEnProceso  = "EN_PROCESO"
	TrabajoCompletado = "COMPLETADO"
	TrabajoFallido    = "FALLIDO"
)

// Trabajo es un proceso largo que corre fuera de la petición HTTP y se consulta por id
// (US-ACA-05 AC-04, US-REP-01).
type Trabajo struct {
	ID           string      `json:"id" bson:"_id"`
	Tipo         string      `json:"tipo" bson:"tipo"`
	Estado       string      `json:"estado" bson:"estado"`
	Progreso     int         `json:"progreso" bson:"progreso"`
	Resultado    interface{} `json:"resultado,omitempty" bson:"resultado,omitempty"`
	Error        string      `json:"error,omitempty" bson:"error,omitempty"`
	CreadoPor    string      `json:"creadoPor" bson:"creadoPor"`
	CreadoEn     time.Time   `json:"creadoEn" bson:"creadoEn"`
	FinalizadoEn *time.Time  `json:"finalizadoEn,omitempty" bson:"finalizadoEn,omitempty"`
}

// TrabajoRepository persiste el estado de los trabajos asíncronos.
type TrabajoRepository interface {
	Crear(ctx context.Context, t *Trabajo) error
	Actualizar(ctx context.Context, t *Trabajo) error
	Obtener(ctx context.Context, id string) (*Trabajo, error)
}
