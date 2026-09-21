// Package auth — emisión de tokens JWT y refresh tokens.
// Este archivo centraliza toda la lógica de creación de tokens para evitar duplicación.
package auth

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/usecase/auth/crypto"
)

// emitTokens crea una nueva familia de tokens para el usuario.
// Se llama en el login inicial.
func (s *Service) emitTokens(ctx context.Context, u *user.Usuario, dispositivoID string) (*TokenPair, error) {
	familiaID := uuid.New().String()
	return s.emitTokensInFamily(ctx, u, dispositivoID, familiaID)
}

// emitTokensInFamily emite un par de tokens dentro de una familia existente.
// Se usa en refresh para mantener la cadena de rotación — AC-05 US-AUT-01.
func (s *Service) emitTokensInFamily(ctx context.Context, u *user.Usuario, dispositivoID, familiaID string) (*TokenPair, error) {
	now := s.clock.Now()

	// Determinar rol activo y permisos (primer rol vigente)
	rolActivo := ""
	var permisos []string
	for _, ra := range u.Roles {
		if ra.VigenciaFin == nil || now.Before(*ra.VigenciaFin) {
			rolActivo = string(ra.Nombre)
			for _, p := range rbac.DefaultPermissions[ra.Nombre] {
				permisos = append(permisos, string(p))
			}
			break
		}
	}

	// Firmar token de acceso JWT
	accessExpiry := now.Add(time.Duration(s.cfg.JWTAccessMinutes) * time.Minute)
	claims := JWTClaims{
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    s.cfg.JWTIssuer,
			Subject:   u.ID,
			ExpiresAt: jwt.NewNumericDate(accessExpiry),
			IssuedAt:  jwt.NewNumericDate(now),
			ID:        shared.NewID(),
		},
		UsuarioID:     u.ID,
		RolActivo:     rolActivo,
		Permisos:      permisos,
		DispositivoID: dispositivoID,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	accessToken, err := token.SignedString([]byte(s.cfg.JWTSecret))
	if err != nil {
		return nil, fmt.Errorf("firmar JWT: %w", err)
	}

	// Crear y persistir refresh token
	rawRefresh := crypto.GenerateSecureToken(64)
	refreshExpiry := now.Add(time.Duration(s.cfg.JWTRefreshDays) * 24 * time.Hour)
	rt := &repository.RefreshToken{
		ID:          shared.NewID(),
		UsuarioID:   u.ID,
		TokenHash:   crypto.HashToken(rawRefresh),
		FamiliaID:   familiaID,
		ExpiraEn:    refreshExpiry,
		Revocado:    false,
		Dispositivo: dispositivoID,
		CreadoEn:    now,
	}
	if err := s.tokens.Create(ctx, rt); err != nil {
		return nil, fmt.Errorf("crear refresh token: %w", err)
	}

	roles := make([]string, 0, len(u.Roles))
	for _, r := range u.Roles {
		roles = append(roles, string(r.Nombre))
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
			Roles:    roles,
			Permisos: permisos,
		},
	}, nil
}

// validateEmailDomain verifica que el correo pertenezca a un dominio autorizado.
// AC-07 US-AUT-01: dominios configurados en AllowedEmailDomains.
func (s *Service) validateEmailDomain(correo string) error {
	if len(s.cfg.AllowedEmailDomains) == 0 {
		return nil
	}
	parts := strings.Split(correo, "@")
	if len(parts) != 2 {
		return shared.NewValidationError("Correo electrónico inválido")
	}
	domain := parts[1]
	for _, d := range s.cfg.AllowedEmailDomains {
		if strings.EqualFold(d, domain) {
			return nil
		}
	}
	return shared.NewAuthError(shared.ErrCredencialesInvalidas,
		"El dominio del correo no está autorizado para este sistema")
}
