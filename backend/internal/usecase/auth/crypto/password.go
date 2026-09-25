// Package password provee las utilidades criptográficas del dominio de autenticación.
// Estas funciones son puras: sin efectos secundarios, sin dependencias de infraestructura.
// AC-04 US-AUT-01: Argon2id para contraseñas, SHA-256 para tokens.
package crypto

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"strings"
	"unicode"

	"golang.org/x/crypto/argon2"

	"github.com/siaa/backend/internal/domain/shared"
)

// HashArgon2id genera un hash Argon2id de la contraseña con salt aleatorio.
// Parámetros: memoria=64MB, tiempo=1, paralelismo=4, clave=32 bytes.
// T-AUT-01.2, AC-04 US-AUT-01.
func HashArgon2id(password string) (string, error) {
	salt := make([]byte, 16)
	if _, err := rand.Read(salt); err != nil {
		return "", err
	}
	hash := argon2.IDKey([]byte(password), salt, 1, 64*1024, 4, 32)
	return fmt.Sprintf("$argon2id$v=19$m=65536,t=1,p=4$%s$%s",
		hex.EncodeToString(salt),
		hex.EncodeToString(hash),
	), nil
}

// VerifyArgon2id verifica una contraseña contra su hash Argon2id almacenado.
// Usa comparación en tiempo constante para evitar timing attacks.
func VerifyArgon2id(password, storedHash string) bool {
	parts := strings.Split(storedHash, "$")
	if len(parts) < 6 {
		return false
	}
	saltHex := parts[4]
	hashHex := parts[5]

	salt, err := hex.DecodeString(saltHex)
	if err != nil {
		return false
	}
	expectedHash, err := hex.DecodeString(hashHex)
	if err != nil {
		return false
	}

	computed := argon2.IDKey([]byte(password), salt, 1, 64*1024, 4, uint32(len(expectedHash)))

	// Comparación en tiempo constante
	if len(computed) != len(expectedHash) {
		return false
	}
	var diff byte
	for i := range computed {
		diff |= computed[i] ^ expectedHash[i]
	}
	return diff == 0
}

// HashToken genera un hash SHA-256 de un token para almacenamiento seguro.
// El token raw nunca se persiste — solo su hash.
func HashToken(token string) string {
	h := sha256.Sum256([]byte(token))
	return hex.EncodeToString(h[:])
}

// GenerateSecureToken genera un token aleatorio criptográficamente seguro.
// length es el número de bytes aleatorios; el resultado es el doble en hex.
func GenerateSecureToken(length int) string {
	b := make([]byte, length)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

// ValidatePassword valida la política de contraseña del sistema.
// AC-05 US-AUT-04: mínimo minLength caracteres + mayúscula + minúscula + dígito.
func ValidatePassword(password string, minLength int) error {
	if len(password) < minLength {
		return shared.NewValidationError(
			fmt.Sprintf("La contraseña debe tener al menos %d caracteres", minLength),
			shared.FieldError{Campo: "password", Error: "demasiado_corta"},
		)
	}
	normalized := strings.ToLower(strings.TrimSpace(password))
	if IsCommonPassword(normalized) {
		return shared.NewValidationError(
			"La contraseña ingresada es demasiado común o vulnerable; seleccione una contraseña diferente",
			shared.FieldError{Campo: "password", Error: "password_comun"},
		)
	}

	hasUpper, hasLower, hasDigit := false, false, false
	for _, r := range password {
		switch {
		case unicode.IsUpper(r):
			hasUpper = true
		case unicode.IsLower(r):
			hasLower = true
		case unicode.IsDigit(r):
			hasDigit = true
		}
	}
	if !hasUpper || !hasLower || !hasDigit {
		return shared.NewValidationError(
			"La contraseña debe contener mayúsculas, minúsculas y números",
			shared.FieldError{Campo: "password", Error: "complejidad_insuficiente"},
		)
	}

	return nil
}

// commonPasswords contiene un diccionario de contraseñas vulnerables y predecibles.
var commonPasswords = map[string]struct{}{
	"password123456":  {},
	"admin12345678":   {},
	"administrator12": {},
	"qwertyuiop12":    {},
	"123456789012":    {},
	"universidad1234": {},
	"bienvenido1234":  {},
	"contrasena1234":  {},
	"colombia2024*":   {},
	"seguridad12345":  {},
	"cambiame123456":  {},
	"docente123456*":  {},
	"estudiante1234":  {},
	"supersecret123":  {},
}

// IsCommonPassword verifica si la contraseña normalizada coincide con la lista negra de contraseñas comunes.
func IsCommonPassword(normalizedPassword string) bool {
	if _, exists := commonPasswords[normalizedPassword]; exists {
		return true
	}
	// Detectar repeticiones triviales o secuencias comunes
	for common := range commonPasswords {
		if strings.Contains(normalizedPassword, common) {
			return true
		}
	}
	return false
}
