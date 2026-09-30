package justificaciones

import (
	"context"
	"errors"
	"fmt"

	"github.com/siaa/backend/internal/domain/justificacion"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// Revisar aplica la transición pedida por el revisor dentro de su ámbito (RF-JUS-002)
// y notifica al solicitante cuando la decisión es final (RF-JUS-005).
func (s *Service) Revisar(ctx context.Context, actor Actor, id string, destino justificacion.Estado, observaciones string) (*justificacion.Justificacion, error) {
	j, err := s.Obtener(ctx, actor, id)
	if err != nil {
		return nil, err
	}
	antes := *j
	antes.Historial = append([]justificacion.Transicion(nil), j.Historial...)
	if err := j.Transitar(destino, actor.UsuarioID, observaciones, s.clock.Now()); err != nil {
		return nil, errorDominio(err)
	}
	if err := s.justificaciones.ActualizarEstado(ctx, j, antes.Estado); err != nil {
		if errors.Is(err, repository.ErrJustificacionModificada) {
			return nil, &shared.DomainError{Code: shared.ErrConflictoUnicidad, Message: "Otra persona ya revisó esta justificación"}
		}
		return nil, err
	}
	s.auditar(ctx, actor, "JUSTIFICACION_"+string(destino), j.ID, &antes, j)
	if destino == justificacion.EstadoAprobada || destino == justificacion.EstadoRechazada {
		s.notificar(ctx, j)
	}
	return j, nil
}

// notificar informa el resultado por push y por correo; un fallo de envío no revierte la decisión.
func (s *Service) notificar(ctx context.Context, j *justificacion.Justificacion) {
	if s.notificador != nil {
		s.notificador.ResultadoJustificacion(ctx, j.DocenteID, j.ID, j.NombreSesion, j.Estado == justificacion.EstadoAprobada)
	}
	if s.correo == nil || s.usuarios == nil {
		return
	}
	u, err := s.usuarios.FindByID(ctx, j.DocenteID)
	if err != nil || u == nil || u.Correo == "" {
		return
	}
	resultado := "aprobada"
	if j.Estado == justificacion.EstadoRechazada {
		resultado = "rechazada"
	}
	cuerpo := fmt.Sprintf("Hola %s,\r\n\r\nTu justificación de la sesión %s fue %s.\r\n", u.Nombre, j.NombreSesion, resultado)
	if j.Observaciones != "" {
		cuerpo += "\r\nObservaciones del revisor: " + j.Observaciones + "\r\n"
	}
	_ = s.correo.Enviar(ctx, u.Correo, "SIAA - Justificación "+resultado, cuerpo)
}
