// Package repository — tokens de refresco y recuperación de contraseña.
// ADR-02: usecase depende de interfaces, no de implementaciones concretas.
package repository

import (
	"context"
	"time"
)

// RefreshToken representa un token de refresco almacenado con su hash SHA-256.
// El token raw nunca se persiste. familiaID permite detectar robo (AC-06 US-AUT-01).
type RefreshToken struct {
	ID          string
	UsuarioID   string
	TokenHash   string
	FamiliaID   string
	ExpiraEn    time.Time
	Revocado    bool
	Dispositivo string
	CreadoEn    time.Time
}

// RecoveryToken es un token de un solo uso para recuperación de contraseña.
type RecoveryToken struct {
	ID        string
	UsuarioID string
	TokenHash string
	ExpiraEn  time.Time
	Usado     bool
	CreadoEn  time.Time
}

// RefreshTokenRepository define operaciones sobre tokens de refresco.
type RefreshTokenRepository interface {
	// Create persiste un nuevo token de refresco.
	Create(ctx context.Context, t *RefreshToken) error
	// FindByHash busca un token por su hash SHA-256.
	FindByHash(ctx context.Context, hash string) (*RefreshToken, error)
	// RevokeByID revoca un token específico.
	RevokeByID(ctx context.Context, id string) error
	// RevokeByFamilia revoca todos los tokens de una familia (detección de robo — AC-06).
	RevokeByFamilia(ctx context.Context, familiaID string) error
	// RevokeByUsuario revoca todos los tokens de un usuario (logout remoto).
	RevokeByUsuario(ctx context.Context, usuarioID string) error
}

// RecoveryTokenRepository define operaciones sobre tokens de recuperación.
type RecoveryTokenRepository interface {
	// Create persiste un nuevo token de recuperación.
	Create(ctx context.Context, t *RecoveryToken) error
	// FindByHash busca un token válido (no usado y no expirado).
	FindByHash(ctx context.Context, hash string) (*RecoveryToken, error)
	// MarkUsed marca un token como consumido.
	MarkUsed(ctx context.Context, id string) error
}
