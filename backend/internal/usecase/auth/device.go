// Package auth — caso de uso de vinculación y gestión de dispositivos confiables (US-AUT-03).
// RF-AUT-004, AC-01..AC-06, T-AUT-03.1..T-AUT-03.7.
package auth

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
)

var (
	ErrDispositivoNoEncontrado = errors.New("dispositivo no encontrado")
	ErrInstalacionIDRequerido  = errors.New("el identificador de instalación es obligatorio")
	ErrRepoDispositivoNoConfig = errors.New("repositorio de dispositivos no configurado")
)

// RegistrarDispositivoInput define los parámetros para registrar o vincular un dispositivo.
type RegistrarDispositivoInput struct {
	UsuarioID     string
	InstalacionID string
	Modelo        string
	SO            string
	VersionApp    string
}

// RegistrarDispositivo vincula un dispositivo en el primer inicio de sesión o solicita aprobación (AC-01, AC-03).
func (s *Service) RegistrarDispositivo(ctx context.Context, input RegistrarDispositivoInput) (*user.Dispositivo, error) {
	if s.dispositivos == nil {
		return nil, ErrRepoDispositivoNoConfig
	}
	if input.InstalacionID == "" {
		return nil, ErrInstalacionIDRequerido
	}

	now := s.clock.Now()

	// 1. Verificar si ya existe este dispositivo vinculado a este usuario
	existente, err := s.dispositivos.FindByInstalacion(ctx, input.UsuarioID, input.InstalacionID)
	if err != nil {
		return nil, fmt.Errorf("error al consultar dispositivo: %w", err)
	}
	if existente != nil {
		existente.Modelo = input.Modelo
		existente.SO = input.SO
		existente.VersionApp = input.VersionApp
		existente.ActualizadoEn = now
		_ = s.dispositivos.Update(ctx, existente)
		return existente, nil
	}

	// 2. Consultar historial de dispositivos del usuario para determinar si es el primero (AC-01) o cambio (AC-03)
	previos, err := s.dispositivos.FindByUsuario(ctx, input.UsuarioID)
	if err != nil {
		return nil, fmt.Errorf("error al consultar dispositivos previos: %w", err)
	}

	tieneConfiableActivo := false
	for _, p := range previos {
		if p.EsValidoParaMarcaje() {
			tieneConfiableActivo = true
			break
		}
	}

	nuevo := &user.Dispositivo{
		ID:            shared.NewID(),
		UsuarioID:     input.UsuarioID,
		InstalacionID: input.InstalacionID,
		Modelo:        input.Modelo,
		SO:            input.SO,
		VersionApp:    input.VersionApp,
		CreadoEn:      now,
		ActualizadoEn: now,
	}

	if !tieneConfiableActivo {
		// Primer dispositivo registrado: queda vinculado como confiable automáticamente (AC-01)
		nuevo.Confiable = true
		nuevo.PendienteAprobacion = false

		if u, err := s.usuarios.FindByID(ctx, input.UsuarioID); err == nil && u != nil {
			u.DispositivoVinculado = &input.InstalacionID
			u.ActualizadoEn = now
			_ = s.usuarios.Update(ctx, u)
		}

		_ = s.auditoria.Create(ctx, &repository.AuditEntry{
			ID:        shared.NewID(),
			Entidad:   "dispositivo",
			EntidadID: nuevo.ID,
			Accion:    "VINCULACION_DISPOSITIVO_INICIAL",
			ActorID:   input.UsuarioID,
			CreadoEn:  now,
		})
	} else {
		// Ya tenía dispositivo: nuevo dispositivo requiere aprobación administrativa (AC-03, AC-05)
		nuevo.Confiable = false
		nuevo.PendienteAprobacion = true

		_ = s.auditoria.Create(ctx, &repository.AuditEntry{
			ID:        shared.NewID(),
			Entidad:   "dispositivo",
			EntidadID: nuevo.ID,
			Accion:    "SOLICITUD_CAMBIO_DISPOSITIVO",
			ActorID:   input.UsuarioID,
			CreadoEn:  now,
		})
	}

	// 3. Detección de anomalía R-03: mismo dispositivo usado por dos usuarios distintos en 24h (AC-04, T-AUT-03.7)
	hace24h := now.Add(-24 * time.Hour)
	recientes, err := s.dispositivos.FindRecentByInstalacion(ctx, input.InstalacionID, hace24h)
	if err == nil {
		for _, r := range recientes {
			if r.UsuarioID != input.UsuarioID {
				_ = s.auditoria.Create(ctx, &repository.AuditEntry{
					ID:        shared.NewID(),
					Entidad:   "dispositivo",
					EntidadID: nuevo.ID,
					Accion:    "ALERTA_ANOMALIA_DISPOSITIVO_COMPARTIDO",
					ActorID:   input.UsuarioID,
					CreadoEn:  now,
				})
				break
			}
		}
	}

	if err := s.dispositivos.Create(ctx, nuevo); err != nil {
		return nil, fmt.Errorf("error al persistir dispositivo: %w", err)
	}

	return nuevo, nil
}

// ListarDispositivosUsuario lista los dispositivos de un usuario (AC-06).
func (s *Service) ListarDispositivosUsuario(ctx context.Context, usuarioID string) ([]*user.Dispositivo, error) {
	if s.dispositivos == nil {
		return nil, ErrRepoDispositivoNoConfig
	}
	return s.dispositivos.FindByUsuario(ctx, usuarioID)
}

// AprobarDispositivo aprueba un cambio de dispositivo, activándolo y revocando los anteriores (AC-03).
func (s *Service) AprobarDispositivo(ctx context.Context, actorID, dispositivoID string) error {
	if s.dispositivos == nil {
		return ErrRepoDispositivoNoConfig
	}

	disp, err := s.dispositivos.FindByID(ctx, dispositivoID)
	if err != nil || disp == nil {
		return ErrDispositivoNoEncontrado
	}

	now := s.clock.Now()

	// Revocar todos los dispositivos previos del usuario
	anteriores, _ := s.dispositivos.FindByUsuario(ctx, disp.UsuarioID)
	for _, ant := range anteriores {
		if ant.ID != disp.ID && ant.Confiable {
			ant.Revocar(now)
			_ = s.dispositivos.Update(ctx, ant)
		}
	}

	disp.Aprobar(now)
	if err := s.dispositivos.Update(ctx, disp); err != nil {
		return fmt.Errorf("error al aprobar dispositivo: %w", err)
	}

	if u, err := s.usuarios.FindByID(ctx, disp.UsuarioID); err == nil && u != nil {
		u.DispositivoVinculado = &disp.InstalacionID
		u.ActualizadoEn = now
		_ = s.usuarios.Update(ctx, u)
	}

	_ = s.auditoria.Create(ctx, &repository.AuditEntry{
		ID:        shared.NewID(),
		Entidad:   "dispositivo",
		EntidadID: disp.ID,
		Accion:    "APROBACION_DISPOSITIVO",
		ActorID:   actorID,
		CreadoEn:  now,
	})

	return nil
}

// RevocarDispositivo invalida un dispositivo confiable (AC-06).
func (s *Service) RevocarDispositivo(ctx context.Context, actorID, dispositivoID string) error {
	if s.dispositivos == nil {
		return ErrRepoDispositivoNoConfig
	}

	disp, err := s.dispositivos.FindByID(ctx, dispositivoID)
	if err != nil || disp == nil {
		return ErrDispositivoNoEncontrado
	}

	now := s.clock.Now()
	disp.Revocar(now)

	if err := s.dispositivos.Update(ctx, disp); err != nil {
		return fmt.Errorf("error al revocar dispositivo: %w", err)
	}

	_ = s.auditoria.Create(ctx, &repository.AuditEntry{
		ID:        shared.NewID(),
		Entidad:   "dispositivo",
		EntidadID: disp.ID,
		Accion:    "REVOCACION_DISPOSITIVO",
		ActorID:   actorID,
		CreadoEn:  now,
	})

	return nil
}
