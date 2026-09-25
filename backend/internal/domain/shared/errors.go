package shared

import (
	"errors"
	"fmt"
)

// ─────────────────────────────────────────────
// Códigos de error de dominio — §9.2 del SRS
// ─────────────────────────────────────────────

type ErrorCode string

const (
	ErrCredencialesInvalidas ErrorCode = "AUTH_CREDENCIALES_INVALIDAS"
	ErrTokenExpirado         ErrorCode = "AUTH_TOKEN_EXPIRADO"
	ErrTokenRevocado         ErrorCode = "AUTH_TOKEN_REVOCADO"
	ErrCuentaBloqueada       ErrorCode = "AUTH_CUENTA_BLOQUEADA"
	ErrDosFactorRequerido    ErrorCode = "AUTH_2FA_REQUERIDO"
	ErrUsuarioInactivo       ErrorCode = "AUTH_USUARIO_INACTIVO"
	ErrPermisosDenegados     ErrorCode = "PERM_DENEGADO"
	ErrAmbitoDenegado        ErrorCode = "AMBITO_DENEGADO"
	ErrValidacion            ErrorCode = "VALIDACION"
	ErrRecursoNoEncontrado   ErrorCode = "RECURSO_NO_ENCONTRADO"
	ErrConflictoHorario      ErrorCode = "CONFLICTO_HORARIO"
	ErrConflictoUnicidad     ErrorCode = "CONFLICTO_UNICIDAD"
	ErrGeometriaInvalida     ErrorCode = "GEOMETRIA_INVALIDA"
	ErrGeometriaSolapada     ErrorCode = "GEOMETRIA_SOLAPADA"
	ErrLimiteTasa            ErrorCode = "LIMITE_TASA"
	ErrInterno               ErrorCode = "ERROR_INTERNO"
)

// DomainError es el error tipado que cruza las capas sin exponer detalles internos al cliente.
type DomainError struct {
	Code    ErrorCode
	Message string
	Cause   error
	Fields  []FieldError
}

type FieldError struct {
	Campo string `json:"campo"`
	Error string `json:"error"`
}

func (e *DomainError) Error() string {
	if e.Cause != nil {
		return fmt.Sprintf("[%s] %s: %v", e.Code, e.Message, e.Cause)
	}
	return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

func (e *DomainError) Unwrap() error { return e.Cause }

// Constructores de errores de dominio frecuentes

func NewValidationError(msg string, fields ...FieldError) *DomainError {
	return &DomainError{Code: ErrValidacion, Message: msg, Fields: fields}
}

func NewNotFoundError(entidad, id string) *DomainError {
	return &DomainError{Code: ErrRecursoNoEncontrado, Message: fmt.Sprintf("%s '%s' no encontrado", entidad, id)}
}

func NewAuthError(code ErrorCode, msg string) *DomainError {
	return &DomainError{Code: code, Message: msg}
}

func NewPermissionError() *DomainError {
	return &DomainError{Code: ErrPermisosDenegados, Message: "No tienes permiso para realizar esta operación"}
}

func NewScopeError() *DomainError {
	return &DomainError{Code: ErrAmbitoDenegado, Message: "El recurso solicitado está fuera de tu ámbito"}
}

// AsDomainError extrae un DomainError de cualquier error.
func AsDomainError(err error) (*DomainError, bool) {
	var de *DomainError
	ok := errors.As(err, &de)
	return de, ok
}
