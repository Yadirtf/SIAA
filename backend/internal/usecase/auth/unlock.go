// Package auth — caso de uso Desbloqueo administrativo de cuentas.
// US-AUT-02, AC-02, T-AUT-02.3.
package auth

import (
	"context"
	"fmt"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// DesbloquearCuenta permite a un administrador desbloquear una cuenta bloqueada por intentos fallidos.
// Restablece el contador de intentos y la fecha de bloqueo, emitiendo una entrada en la bitácora de auditoría.
func (s *Service) DesbloquearCuenta(ctx context.Context, adminID, usuarioID string) error {
	usuario, err := s.usuarios.FindByID(ctx, usuarioID)
	if err != nil || usuario == nil {
		return shared.NewNotFoundError("usuario", usuarioID)
	}

	if err := s.usuarios.ResetIntentosFallidos(ctx, usuario.ID); err != nil {
		return fmt.Errorf("desbloquear usuario: %w", err)
	}

	// Registrar en auditoría la acción administrativa con el actor — AC-02
	_ = s.auditoria.Create(ctx, &repository.AuditEntry{
		ID:        shared.NewID(),
		Entidad:   "usuario",
		EntidadID: usuario.ID,
		Accion:    "DESBLOQUEO_CUENTA",
		ActorID:   adminID,
		CreadoEn:  s.clock.Now(),
	})

	return nil
}
