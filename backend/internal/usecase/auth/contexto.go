// Package auth — Alternancia de contexto de rol para usuarios con múltiples roles.
// Satisface US-ROL-04, AC-01..AC-04 y RF-ROL-004.
package auth

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/usecase/auth/crypto"
)

// CambiarContextoRol valida que el usuario posea el rol solicitado, que esté vigente
// temporalmente y emite un nuevo par de tokens con el rol y permisos activados.
func (s *Service) CambiarContextoRol(ctx context.Context, usuarioID, rolSolicitado string) (*TokenPair, error) {
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

	// 2. Extraer los permisos del nuevo rol activo
	permisosRole := rbac.DefaultPermissions[rolAsignado.Nombre]
	permisosStrings := make([]string, 0, len(permisosRole))
	for _, p := range permisosRole {
		permisosStrings = append(permisosStrings, string(p))
	}

	// 3. Emitir nuevo JWT con rol activo actualizado — US-ROL-04 AC-04
	accessExpiry := now.Add(time.Duration(s.cfg.JWTAccessMinutes) * time.Minute)
	claims := JWTClaims{
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    s.cfg.JWTIssuer,
			Subject:   u.ID,
			ExpiresAt: jwt.NewNumericDate(accessExpiry),
			IssuedAt:  jwt.NewNumericDate(now),
			ID:        shared.NewID(),
		},
		UsuarioID: u.ID,
		RolActivo: rolSolicitado,
		Permisos:  permisosStrings,
		Ambitos:   u.Ambitos,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	accessToken, err := token.SignedString([]byte(s.cfg.JWTSecret))
	if err != nil {
		return nil, fmt.Errorf("firmar token nuevo: %w", err)
	}

	// 4. Generar nuevo refresh token
	rawRefresh := crypto.GenerateSecureToken(64)
	refreshExpiry := now.Add(time.Duration(s.cfg.JWTRefreshDays) * 24 * time.Hour)
	familiaID := shared.NewID()

	rt := &repository.RefreshToken{
		ID:        shared.NewID(),
		TokenHash: crypto.HashToken(rawRefresh),
		UsuarioID: u.ID,
		FamiliaID: familiaID,
		ExpiraEn:  refreshExpiry,
		CreadoEn:  now,
		Revocado:  false,
	}
	if err := s.tokens.Create(ctx, rt); err != nil {
		return nil, fmt.Errorf("guardar refresh token: %w", err)
	}

	// 5. Registrar evento en auditoría — US-ROL-04 AC-02, RF-AUD-002
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

	rolesList := make([]string, 0, len(u.Roles))
	for _, r := range u.Roles {
		rolesList = append(rolesList, string(r.Nombre))
	}

	return &TokenPair{
		AccessToken:  accessToken,
		RefreshToken: rawRefresh,
		ExpiraEn:     refreshExpiry,
		Usuario: &UsuarioInfo{
			ID:       u.ID,
			Correo:   u.Correo,
			Nombre:   u.Nombre,
			Apellido: u.Apellido,
			Roles:    rolesList,
			Permisos: permisosStrings,
		},
	}, nil
}
