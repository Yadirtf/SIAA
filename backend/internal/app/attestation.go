package app

import (
	"context"

	"github.com/siaa/backend/internal/platform/config"
	"github.com/siaa/backend/internal/platform/integridad"
	applog "github.com/siaa/backend/internal/platform/log"
)

// verificadorAttestation construye el verificador de Play Integrity si está configurado.
// Devuelve nil sin configuración: el parámetro exigir_attestation rechazará entonces todo
// marcaje, por eso se deja constancia en el log al arrancar.
func verificadorAttestation(cfg *config.Config, log *applog.Logger) *integridad.PlayIntegrity {
	if cfg.PlayIntegrityPaquete == "" || cfg.PlayIntegrityCredenciales == "" {
		log.Info("Play Integrity no configurado: ningún marcaje tendrá attestation válida")
		return nil
	}
	v, err := integridad.NuevoPlayIntegrity(context.Background(), cfg.PlayIntegrityPaquete, cfg.PlayIntegrityCredenciales)
	if err != nil {
		log.Error("no se pudo iniciar Play Integrity", applog.Err(err))
		return nil
	}
	return v
}
