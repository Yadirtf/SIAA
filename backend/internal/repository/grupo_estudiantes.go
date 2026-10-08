package repository

import (
	"context"
	"time"
)

// GrupoEstudiantesRepository guarda qué estudiantes integran cada grupo (US-MAR-13, US-MAR-14).
// No es una matrícula académica (fuera de alcance, §2): es la lista de quienes pueden marcar
// en las sesiones del grupo y aparecen en su lista manual.
type GrupoEstudiantesRepository interface {
	Listar(ctx context.Context, grupoID string) ([]string, error)
	// Reemplazar deja exactamente esos estudiantes en el grupo.
	Reemplazar(ctx context.Context, grupoID string, estudianteIDs []string, actorID string, ahora time.Time) error
	Pertenece(ctx context.Context, grupoID, estudianteID string) (bool, error)
	GruposDeEstudiante(ctx context.Context, estudianteID string) ([]string, error)
}
