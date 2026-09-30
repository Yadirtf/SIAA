// Package dto define los Data Transfer Objects de autenticación.
// Toda validación de entrada ocurre aquí antes de llegar al caso de uso.
package dto

// ─── Peticiones ───────────────────────────────────────────────

// LoginRequest es el cuerpo de POST /auth/login.
type LoginRequest struct {
	Correo        string `json:"correo"      validate:"required,email"`
	Password      string `json:"password"    validate:"required,min=1"`
	DispositivoID string `json:"dispositivoId,omitempty"`
}

// RefreshRequest es el cuerpo de POST /auth/refresh.
type RefreshRequest struct {
	RefreshToken  string `json:"refreshToken" validate:"required"`
	DispositivoID string `json:"dispositivoId,omitempty"`
}

// RecuperarRequest es el cuerpo de POST /auth/recuperar.
type RecuperarRequest struct {
	Correo string `json:"correo" validate:"required,email"`
}

// ConfirmarRecuperarRequest es el cuerpo de POST /auth/recuperar/confirmar.
type ConfirmarRecuperarRequest struct {
	Token    string `json:"token"    validate:"required"`
	Password string `json:"password" validate:"required,min=12"`
}

// LogoutRequest es el cuerpo de POST /auth/logout.
type LogoutRequest struct {
	RefreshToken string `json:"refreshToken" validate:"required"`
}

// CambiarContextoRequest es el cuerpo de POST /auth/contexto (US-ROL-04).
type CambiarContextoRequest struct {
	Rol string `json:"rol" validate:"required"`
}

// RevocarSesionesRequest es el cuerpo de POST /usuarios/:id/revocar-sesiones (US-AUT-07).
type RevocarSesionesRequest struct {
	Motivo string `json:"motivo" validate:"required"`
}

// ActivarTOTPRequest es el cuerpo de POST /auth/totp/activar (US-AUT-05).
type ActivarTOTPRequest struct {
	Codigo string `json:"codigo" validate:"required,len=6"`
}

// VerificarTOTPRequest es el cuerpo de POST /auth/totp/verificar (US-AUT-05).
type VerificarTOTPRequest struct {
	UsuarioID     string `json:"usuarioId" validate:"required"`
	Codigo        string `json:"codigo" validate:"required"`
	DispositivoID string `json:"dispositivoId,omitempty"`
}

// ─── Respuestas ────────────────────────────────────────────────

// TokenPairResponse es la respuesta de login/refresh con los tokens.
type TokenPairResponse struct {
	AccessToken  string      `json:"accessToken"`
	RefreshToken string      `json:"refreshToken"`
	ExpiraEn     string      `json:"expiraEn"` // ISO 8601
	TipoToken    string      `json:"tipoToken"`
	Usuario      interface{} `json:"usuario"`
}

// MensajeResponse es una respuesta genérica de mensaje.
type MensajeResponse struct {
	Mensaje string `json:"mensaje"`
}
