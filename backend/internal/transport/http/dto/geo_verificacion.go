// Package dto — verificación complementaria del espacio (RF-GEO-016).
package dto

import "github.com/siaa/backend/internal/domain/geo"

// VerificacionEspacioDTO expone y recibe los métodos complementarios del aula (RF-GEO-016).
type VerificacionEspacioDTO struct {
	WifiBssids []string `json:"wifiBssids"`
	BleUUID    string   `json:"bleUuid,omitempty"`
	QrCodigo   string   `json:"qrCodigo,omitempty"`
}

func verificacionADTO(v *geo.VerificacionEspacio) *VerificacionEspacioDTO {
	if v == nil {
		return nil
	}
	return &VerificacionEspacioDTO{WifiBssids: v.WifiBssids, BleUUID: v.BleUUID, QrCodigo: v.QrCodigo}
}
