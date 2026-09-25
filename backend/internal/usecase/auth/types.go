// Package auth — tipos compartidos del caso de uso de autenticación.
// US-AUT-01, US-AUT-04.
package auth

import (
	"context"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"github.com/siaa/backend/internal/domain/rbac"
)

// LoginInput es la entrada del caso de uso de login.
type LoginInput struct {
	Correo        string
	Password      string
	DispositivoID string // Para vinculación de dispositivo
}

// TokenPair es el resultado del login: token de acceso + token de refresco.
type TokenPair struct {
	AccessToken  string
	RefreshToken string
	ExpiraEn     time.Time
	Usuario      *UsuarioInfo
}

// UsuarioInfo es la información del usuario devuelta al cliente tras la autenticación.
type UsuarioInfo struct {
	ID       string   `json:"id"`
	Correo   string   `json:"correo"`
	Nombre   string   `json:"nombre"`
	Apellido string   `json:"apellido"`
	Roles    []string `json:"roles"`
	Permisos []string `json:"permisos"`
}

// JWTClaims son los claims del token de acceso JWT.
// Se incluyen en el token y se leen en el middleware de autenticación.
type JWTClaims struct {
	jwt.RegisteredClaims
	UsuarioID     string       `json:"uid"`
	RolActivo     string       `json:"rol"`
	Permisos      []string     `json:"perms"`
	DispositivoID string       `json:"did,omitempty"`
	Ambitos       []rbac.Scope `json:"ambs,omitempty"`
}

// Mailer es el contrato para el envío de correos del caso de uso de auth.
// Se inyecta en NewService; la implementación concreta vive en platform/mailer.
type Mailer interface {
	SendRecovery(ctx context.Context, to, token string) error
}
