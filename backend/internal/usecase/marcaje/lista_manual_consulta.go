package marcaje

import (
	"context"
	"sort"
	"strings"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
)

// EstudianteListaDTO es una fila de la lista del grupo con su marcaje de entrada actual.
type EstudianteListaDTO struct {
	ID        string `json:"id"`
	Nombre    string `json:"nombre"`
	Correo    string `json:"correo"`
	Resultado string `json:"resultado,omitempty"` // vacío = sin registro
	Origen    string `json:"origen,omitempty"`
	// Bloqueado: tiene un marcaje válido que la lista manual no puede cambiar (AC-04).
	Bloqueado bool `json:"bloqueado"`
}

// ListaSesionDTO es la lista manual de una sesión (US-MAR-14 AC-01).
type ListaSesionDTO struct {
	SesionID    string               `json:"sesionId"`
	Estudiantes []EstudianteListaDTO `json:"estudiantes"`
}

// Consultar devuelve a los estudiantes del grupo y lo que ya consta de cada uno.
func (uc *ListaManualUseCase) Consultar(ctx context.Context, sesionID, docenteID string) (*ListaSesionDTO, error) {
	s, err := uc.sesionDelDocente(ctx, sesionID, docenteID, uc.reloj())
	if err != nil {
		return nil, err
	}
	integrantes, err := uc.integrantes(ctx, s)
	if err != nil {
		return nil, err
	}
	res := &ListaSesionDTO{SesionID: sesionID, Estudiantes: make([]EstudianteListaDTO, 0, len(integrantes))}
	for id := range integrantes {
		fila := EstudianteListaDTO{ID: id, Nombre: id}
		if uc.usuarioRepo != nil {
			if u, err := uc.usuarioRepo.FindByID(ctx, id); err == nil && u != nil {
				fila.Nombre = strings.TrimSpace(u.Nombre + " " + u.Apellido)
				fila.Correo = u.Correo
			}
		}
		if previo, _ := uc.marcajeRepo.ObtenerPrevio(ctx, sesionID, id, domainMarcaje.TipoEntrada); previo != nil {
			fila.Resultado = string(previo.Resultado)
			fila.Origen = string(previo.Origen)
			fila.Bloqueado = previo.ConsolidaSesion()
		}
		res.Estudiantes = append(res.Estudiantes, fila)
	}
	sort.SliceStable(res.Estudiantes, func(i, j int) bool {
		return strings.ToLower(res.Estudiantes[i].Nombre) < strings.ToLower(res.Estudiantes[j].Nombre)
	})
	return res, nil
}
