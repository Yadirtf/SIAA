// Package dto — Data Transfer Objects para dispositivos confiables (US-AUT-03).
package dto

import (
	"time"

	"github.com/siaa/backend/internal/domain/user"
)

// RegistrarDispositivoRequest representa la solicitud de vinculación de un dispositivo (AC-01, AC-03).
type RegistrarDispositivoRequest struct {
	InstalacionID string `json:"instalacionId" validate:"required"`
	Modelo        string `json:"modelo"`
	SO            string `json:"so"`
	VersionApp    string `json:"versionApp"`
}

// DispositivoResponse es la respuesta serializada de un dispositivo confiable.
type DispositivoResponse struct {
	ID                  string     `json:"id"`
	UsuarioID           string     `json:"usuarioId"`
	InstalacionID       string     `json:"instalacionId"`
	Modelo              string     `json:"modelo"`
	SO                  string     `json:"so"`
	VersionApp          string     `json:"versionApp"`
	Confiable           bool       `json:"confiable"`
	PendienteAprobacion bool       `json:"pendienteAprobacion"`
	CreadoEn            time.Time  `json:"creadoEn"`
	ActualizadoEn       time.Time  `json:"actualizadoEn"`
	RevocadoEn          *time.Time `json:"revocadoEn,omitempty"`
}

// DispositivoToResponse mapea una entidad Dispositivo a su DTO de respuesta.
func DispositivoToResponse(d *user.Dispositivo) DispositivoResponse {
	return DispositivoResponse{
		ID:                  d.ID,
		UsuarioID:           d.UsuarioID,
		InstalacionID:       d.InstalacionID,
		Modelo:              d.Modelo,
		SO:                  d.SO,
		VersionApp:          d.VersionApp,
		Confiable:           d.Confiable,
		PendienteAprobacion: d.PendienteAprobacion,
		CreadoEn:            d.CreadoEn,
		ActualizadoEn:       d.ActualizadoEn,
		RevocadoEn:          d.RevocadoEn,
	}
}
