package security

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"errors"
	"fmt"
)

// Cifrador protege contenido en reposo con AES-256-GCM (soportes de justificaciones).
type Cifrador struct {
	aead cipher.AEAD
}

// NuevoCifrador deriva una clave de 256 bits del secreto con SHA-256.
func NuevoCifrador(secreto string) (*Cifrador, error) {
	if secreto == "" {
		return nil, errors.New("secreto de cifrado vacío")
	}
	clave := sha256.Sum256([]byte("siaa-adjuntos:" + secreto))
	bloque, err := aes.NewCipher(clave[:])
	if err != nil {
		return nil, fmt.Errorf("crear cifrador: %w", err)
	}
	aead, err := cipher.NewGCM(bloque)
	if err != nil {
		return nil, fmt.Errorf("crear GCM: %w", err)
	}
	return &Cifrador{aead: aead}, nil
}

// Cifrar devuelve nonce || texto cifrado.
func (c *Cifrador) Cifrar(plano []byte) ([]byte, error) {
	nonce := make([]byte, c.aead.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		return nil, fmt.Errorf("generar nonce: %w", err)
	}
	return c.aead.Seal(nonce, nonce, plano, nil), nil
}

// Descifrar invierte Cifrar y falla si el contenido fue alterado.
func (c *Cifrador) Descifrar(cifrado []byte) ([]byte, error) {
	n := c.aead.NonceSize()
	if len(cifrado) < n {
		return nil, errors.New("contenido cifrado inválido")
	}
	plano, err := c.aead.Open(nil, cifrado[:n], cifrado[n:], nil)
	if err != nil {
		return nil, fmt.Errorf("descifrar: %w", err)
	}
	return plano, nil
}
