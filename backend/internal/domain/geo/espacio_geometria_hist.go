// Package geo — dominio de cartografía y espacios.
// US-GEO-06: versionado inmutable de geometrías de espacios.
package geo

import (
	"time"

	"github.com/siaa/backend/internal/domain/shared"
)

// EspacioGeometriaHist representa una instantánea inmutable de la geometría de un espacio.
// AC-01: Cada modificación archiva la versión anterior con fecha, autor y número de versión.
// AC-05: El histórico es inmutable: no admite edición ni eliminación.
type EspacioGeometriaHist struct {
	ID                      string         `json:"id" bson:"_id,omitempty"`
	EspacioID               string         `json:"espacioId" bson:"espacioId"`
	Version                 int            `json:"version" bson:"version"`
	Geometria               GeoPolygon     `json:"geometria" bson:"geometria"`
	AreaMetrosCuadrados     float64        `json:"areaMetrosCuadrados" bson:"areaMetrosCuadrados"`
	Centroide               *GeoPoint      `json:"centroide" bson:"centroide"`
	MetodoCaptura           *MetodoCaptura `json:"metodoCaptura,omitempty" bson:"metodoCaptura,omitempty"`
	PrecisionPromedioMetros *float64       `json:"precisionPromedioMetros,omitempty" bson:"precisionPromedioMetros,omitempty"`
	CreadoPor               string         `json:"creadoPor" bson:"creadoPor"`
	CreadoEn                time.Time      `json:"creadoEn" bson:"creadoEn"`
	MotivoCambio            string         `json:"motivoCambio,omitempty" bson:"motivoCambio,omitempty"`
}

// NewEspacioGeometriaHist crea un registro histórico a partir de un espacio existente.
func NewEspacioGeometriaHist(
	espacio *Espacio,
	actor string,
	motivo string,
	now time.Time,
) (*EspacioGeometriaHist, error) {
	if espacio == nil || espacio.Geometria == nil {
		return nil, shared.NewValidationError("No se puede archivar una geometría nula", shared.FieldError{
			Campo: "geometria",
			Error: "GEOMETRÍA_REQUERIDA",
		})
	}

	return &EspacioGeometriaHist{
		EspacioID:               espacio.ID,
		Version:                 espacio.VersionGeometria,
		Geometria:               *espacio.Geometria,
		AreaMetrosCuadrados:     espacio.AreaMetrosCuadrados,
		Centroide:               espacio.Centroide,
		MetodoCaptura:           espacio.MetodoCaptura,
		PrecisionPromedioMetros: espacio.PrecisionPromedioMetros,
		CreadoPor:               actor,
		CreadoEn:                now,
		MotivoCambio:            motivo,
	}, nil
}
