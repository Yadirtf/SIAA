// Package marcaje — attestation de la app verificada en el servidor (paso 3 del motor).
// La bandera attestationOk que envía el cliente nunca se usa: solo cuenta el veredicto que
// el servidor obtiene al verificar el token contra Play Integrity.
package marcaje

import (
	"context"
	"crypto/sha256"
	"encoding/hex"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
)

// VerificadorAttestation descifra y evalúa un token de attestation. Devuelve nil si es válido.
type VerificadorAttestation interface {
	Verificar(ctx context.Context, token, hashSolicitud string) error
}

// WithAttestation habilita la verificación de tokens de Play Integrity.
func (uc *CrearMarcajeUseCase) WithAttestation(v VerificadorAttestation) *CrearMarcajeUseCase {
	uc.attestation = v
	return uc
}

// HashSolicitud vincula el token a un intento concreto: la app lo calcula igual y lo envía
// como requestHash al pedir el token, así un token no sirve para otra sesión ni otro intento.
func HashSolicitud(sesionID string, tipo domainMarcaje.TipoMarcaje, idempotencyKey string) string {
	suma := sha256.Sum256([]byte(sesionID + "|" + string(tipo) + "|" + idempotencyKey))
	return hex.EncodeToString(suma[:])
}

// resolverAttestation reemplaza la bandera del cliente por el resultado de la verificación.
func (uc *CrearMarcajeUseCase) resolverAttestation(ctx context.Context, req *domainMarcaje.SolicitudMarcaje) {
	token := req.Integridad.AttestationToken
	req.Integridad.AttestationOk = false
	req.Integridad.AttestationToken = ""
	if uc.attestation == nil || token == "" {
		return
	}
	hash := HashSolicitud(req.SesionID, req.Tipo, req.IdempotencyKey)
	req.Integridad.AttestationOk = uc.attestation.Verificar(ctx, token, hash) == nil
}
