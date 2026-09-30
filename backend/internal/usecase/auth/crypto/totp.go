// Package crypto — Implementación RFC 6238 TOTP (Time-based One-time Password).
// Satisface US-AUT-05, AC-01..AC-04 y RF-AUT-003.
package crypto

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha1"
	"encoding/base32"
	"encoding/binary"
	"fmt"
	"strings"
	"time"
)

const (
	totpStepSeconds = 30
	totpDigits      = 6
	totpModulus     = 1000000
)

// GenerateTOTPSecret genera un secreto aleatorio de 20 bytes en base32 (sin padding).
func GenerateTOTPSecret() (string, error) {
	bytes := make([]byte, 20)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(bytes), nil
}

// GenerateTOTPCode calcula el código de 6 dígitos para una marca de tiempo dada.
func GenerateTOTPCode(secretBase32 string, t time.Time) (string, error) {
	secretBytes, err := base32.StdEncoding.WithPadding(base32.NoPadding).DecodeString(
		strings.ToUpper(strings.TrimSpace(secretBase32)),
	)
	if err != nil {
		return "", fmt.Errorf("decodificar base32 secret: %w", err)
	}

	counter := uint64(t.Unix()) / totpStepSeconds
	buf := make([]byte, 8)
	binary.BigEndian.PutUint64(buf, counter)

	mac := hmac.New(sha1.New, secretBytes)
	mac.Write(buf)
	hash := mac.Sum(nil)

	// Truncamiento dinámico RFC 4226
	offset := hash[len(hash)-1] & 0x0f
	binaryCode := binary.BigEndian.Uint32(hash[offset:offset+4]) & 0x7fffffff

	code := binaryCode % totpModulus
	return fmt.Sprintf("%06d", code), nil
}

// ValidateTOTPCode valida un código de 6 dígitos con ventana de tolerancia de ±1 paso (±30s).
// Satisface US-AUT-05 AC-02.
func ValidateTOTPCode(secretBase32 string, code string, t time.Time) bool {
	code = strings.TrimSpace(code)
	if len(code) != totpDigits {
		return false
	}

	// Probar pasos t - 30s, t, t + 30s
	steps := []time.Duration{-totpStepSeconds * time.Second, 0, totpStepSeconds * time.Second}
	for _, step := range steps {
		expected, err := GenerateTOTPCode(secretBase32, t.Add(step))
		if err == nil && expected == code {
			return true
		}
	}
	return false
}

// GenerateBackupCodes genera N códigos de respaldo aleatorios y sus hashes SHA-256.
// Satisface US-AUT-05 AC-03 (8 códigos de un solo uso).
func GenerateBackupCodes(count int) (plaintext []string, hashed []string, err error) {
	plaintext = make([]string, count)
	hashed = make([]string, count)

	for i := 0; i < count; i++ {
		code := strings.ToUpper(GenerateSecureToken(4)) // 8 caracteres hexadecimales legibles
		plaintext[i] = code
		hashed[i] = HashToken(code)
	}

	return plaintext, hashed, nil
}
