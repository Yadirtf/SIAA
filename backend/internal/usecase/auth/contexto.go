// Package auth — Alternancia de contexto de rol para usuarios con múltiples roles.
// Satisface US-ROL-04, AC-01..AC-04 y RF-ROL-004.
package auth

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
)

// CambiarContextoRol valida que el usuario posea el rol solicitado, que esté vigente
// temporalmente y emite un nuevo par de tokens con el rol y permisos activados.
func (s *Service) CambiarContextoRol(ctx context.Context, usuarioID, rolSolicitado, dispositivoID string) (*TokenPair, error) {
	usuarioID = strings.TrimSpace(usuarioID)
	rolSolicitado = strings.TrimSpace(rolSolicitado)

	if usuarioID == "" || rolSolicitado == "" {
		return nil, shared.NewValidationError("El usuario y el rol solicitado son requeridos")
	}

	u, err := s.usuarios.FindByID(ctx, usuarioID)
	if err != nil || u == nil {
		return nil, shared.NewNotFoundError("Usuario", usuarioID)
	}

	if !u.Activo || u.Eliminado {
		return nil, shared.NewAuthError(shared.ErrUsuarioInactivo, "Usuario inactivo")
	}

	now := s.clock.Now()

	// 1. Validar que el rol pertenezca al usuario y se encuentre vigente — US-ROL-04 AC-03, US-ROL-05 AC-01
	var rolAsignado *user.RolAsignado
	for _, ra := range u.Roles {
		if string(ra.Nombre) == rolSolicitado {
			rolAsignado = &ra
			break
		}
	}

	if rolAsignado == nil {
		return nil, shared.NewAuthError(shared.ErrPermisosDenegados,
			fmt.Sprintf("El usuario no tiene asignado el rol %s", rolSolicitado))
	}

	if !rolAsignado.IsVigente(now) {
		return nil, shared.NewAuthError(shared.ErrPermisosDenegados,
			fmt.Sprintf("El rol %s se encuentra fuera de su vigencia temporal", rolSolicitado))
	}

	// 2. Emitir un nuevo par con el rol activo; el dispositivo del token actual se conserva y
	// el refresco mantiene este contexto — US-ROL-04 AC-04.
	pair, err := s.emitTokensInFamily(ctx, u, dispositivoID, shared.NewID(), rolSolicitado)
	if err != nil {
		return nil, err
	}

	// 3. Registrar evento en auditoría — US-ROL-04 AC-02, RF-AUD-002
	if s.auditoria != nil {
		_ = s.auditoria.Create(ctx, &repository.AuditEntry{
			Entidad:   "Usuario",
			EntidadID: u.ID,
			Accion:    "CAMBIO_CONTEXTO_ROL",
			ActorID:   u.ID,
			RolActivo: rolSolicitado,
			CreadoEn:  now,
			ValorNuevo: map[string]string{
				"rolNuevo":   rolSolicitado,
				"usuarioID":  u.ID,
				"cambiadoEn": now.Format(time.RFC3339),
			},
		})
	}

	return pair, nil
}
