// Package integridad verifica en el servidor la attestation de la app móvil (Play Integrity).
// El cliente nunca decide si su attestation es válida: solo aporta el token (§ seguridad, R-02).
package integridad

import (
	"errors"
	"fmt"
	"time"
)

// Errores de verificación; todos significan "attestation no válida".
var (
	ErrTokenVacio        = errors.New("attestation: token vacío")
	ErrPaqueteDistinto   = errors.New("attestation: el token pertenece a otro paquete")
	ErrHashDistinto      = errors.New("attestation: el token no corresponde a esta solicitud")
	ErrTokenVencido      = errors.New("attestation: token fuera de vigencia")
	ErrAppNoReconocida   = errors.New("attestation: la app no es una instalación reconocida por Play")
	ErrDispositivoDudoso = errors.New("attestation: el dispositivo no supera la integridad")
	ErrRespuestaInvalida = errors.New("attestation: respuesta de Play Integrity inválida")
	ErrNoConfigurado     = errors.New("attestation: verificación no configurada en el servidor")
)

// payload es la parte de tokenPayloadExternal que el sistema evalúa.
type payload struct {
	RequestDetails struct {
		RequestPackageName string `json:"requestPackageName"`
		RequestHash        string `json:"requestHash"`
		TimestampMillis    string `json:"timestampMillis"`
	} `json:"requestDetails"`
	AppIntegrity struct {
		AppRecognitionVerdict string `json:"appRecognitionVerdict"`
	} `json:"appIntegrity"`
	DeviceIntegrity struct {
		DeviceRecognitionVerdict []string `json:"deviceRecognitionVerdict"`
	} `json:"deviceIntegrity"`
}

// evaluarVeredicto aplica la política institucional al veredicto ya descifrado por Google:
// mismo paquete, misma solicitud, emitido hace menos de `vigencia`, app reconocida por Play
// y dispositivo con integridad (MEETS_DEVICE_INTEGRITY o MEETS_STRONG_INTEGRITY).
func evaluarVeredicto(p payload, paquete, hashEsperado string, ahora time.Time, vigencia time.Duration) error {
	if p.RequestDetails.RequestPackageName != paquete {
		return ErrPaqueteDistinto
	}
	if p.RequestDetails.RequestHash != hashEsperado {
		return ErrHashDistinto
	}
	var ms int64
	if _, err := fmt.Sscan(p.RequestDetails.TimestampMillis, &ms); err != nil {
		return ErrRespuestaInvalida
	}
	emitido := time.UnixMilli(ms)
	if ahora.Sub(emitido) > vigencia || emitido.Sub(ahora) > time.Minute {
		return ErrTokenVencido
	}
	if p.AppIntegrity.AppRecognitionVerdict != "PLAY_RECOGNIZED" {
		return ErrAppNoReconocida
	}
	for _, v := range p.DeviceIntegrity.DeviceRecognitionVerdict {
		if v == "MEETS_DEVICE_INTEGRITY" || v == "MEETS_STRONG_INTEGRITY" {
			return nil
		}
	}
	return ErrDispositivoDudoso
}
