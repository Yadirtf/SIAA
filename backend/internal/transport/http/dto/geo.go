// Package dto — Data Transfer Objects para la jerarquía física y cartografía (US-GEO-01).
package dto

import (
	"time"

	"github.com/siaa/backend/internal/domain/geo"
)

// ─── SEDES ───────────────────────────────────────────────────

type CrearSedeRequest struct {
	Codigo    string `json:"codigo" validate:"required"`
	Nombre    string `json:"nombre" validate:"required"`
	Direccion string `json:"direccion"`
}

type SedeResponse struct {
	ID            string    `json:"id"`
	Codigo        string    `json:"codigo"`
	Nombre        string    `json:"nombre"`
	Direccion     string    `json:"direccion,omitempty"`
	Activo        bool      `json:"activo"`
	CreadoEn      time.Time `json:"creadoEn"`
	ActualizadoEn time.Time `json:"actualizadoEn"`
}

func SedeToResponse(s *geo.Sede) SedeResponse {
	return SedeResponse{
		ID:            s.ID,
		Codigo:        s.Codigo,
		Nombre:        s.Nombre,
		Direccion:     s.Direccion,
		Activo:        s.Activo,
		CreadoEn:      s.CreadoEn,
		ActualizadoEn: s.ActualizadoEn,
	}
}

// ─── BLOQUES ─────────────────────────────────────────────────

type CrearBloqueRequest struct {
	SedeID string `json:"sedeId" validate:"required"`
	Codigo string `json:"codigo" validate:"required"`
	Nombre string `json:"nombre" validate:"required"`
	Pisos  []int  `json:"pisos"`
}

type BloqueResponse struct {
	ID            string    `json:"id"`
	SedeID        string    `json:"sedeId"`
	Codigo        string    `json:"codigo"`
	Nombre        string    `json:"nombre"`
	Pisos         []int     `json:"pisos"`
	Activo        bool      `json:"activo"`
	CreadoEn      time.Time `json:"creadoEn"`
	ActualizadoEn time.Time `json:"actualizadoEn"`
}

func BloqueToResponse(b *geo.Bloque) BloqueResponse {
	return BloqueResponse{
		ID:            b.ID,
		SedeID:        b.SedeID,
		Codigo:        b.Codigo,
		Nombre:        b.Nombre,
		Pisos:         b.Pisos,
		Activo:        b.Activo,
		CreadoEn:      b.CreadoEn,
		ActualizadoEn: b.ActualizadoEn,
	}
}

// ─── ESPACIOS ────────────────────────────────────────────────

// CrearEspacioRequest implementa AC-02: sede y espacio obligatorios; torre, bloque y piso opcionales.
type CrearEspacioRequest struct {
	SedeID              string              `json:"sedeId" validate:"required"`
	Torre               *string             `json:"torre,omitempty"`
	BloqueID            *string             `json:"bloqueId,omitempty"`
	Piso                *int                `json:"piso,omitempty"`
	Codigo              string              `json:"codigo" validate:"required"`
	Nombre              string              `json:"nombre" validate:"required"`
	Capacidad           int                 `json:"capacidad"`
	Tipo                geo.TipoEspacio     `json:"tipo" validate:"required"`
	FacultadResponsable string              `json:"facultadResponsable,omitempty"`
	Estado              geo.EstadoEspacio   `json:"estado,omitempty"`
	NivelValidacion     geo.NivelValidacion `json:"nivelValidacion,omitempty"`
	BufferMetros        float64             `json:"bufferMetros,omitempty"`
}

type ActualizarEspacioRequest struct {
	SedeID              *string              `json:"sedeId,omitempty"`
	Torre               *string              `json:"torre,omitempty"`
	BloqueID            *string              `json:"bloqueId,omitempty"`
	Piso                *int                 `json:"piso,omitempty"`
	Codigo              *string              `json:"codigo,omitempty"`
	Nombre              *string              `json:"nombre,omitempty"`
	Capacidad           *int                 `json:"capacidad,omitempty"`
	Tipo                *geo.TipoEspacio     `json:"tipo,omitempty"`
	FacultadResponsable *string              `json:"facultadResponsable,omitempty"`
	Estado              *geo.EstadoEspacio   `json:"estado,omitempty"`
	NivelValidacion     *geo.NivelValidacion `json:"nivelValidacion,omitempty"`
	BufferMetros        *float64             `json:"bufferMetros,omitempty"`
	ConfirmarImpacto    bool                 `json:"confirmarImpacto,omitempty"`
}

type ActualizarGeometriaRequest struct {
	Coordenadas             [][2]float64      `json:"coordenadas" validate:"required"`
	MetodoCaptura           geo.MetodoCaptura `json:"metodoCaptura" validate:"required"`
	PrecisionPromedioMetros *float64          `json:"precisionPromedioMetros,omitempty"`
	ConfirmarSolapamiento   bool              `json:"confirmarSolapamiento,omitempty"`
	MotivoSolapamiento      string            `json:"motivoSolapamiento,omitempty"`
}

type GeometriaResponse struct {
	Tipo        string         `json:"tipo"`
	Coordinates [][][2]float64 `json:"coordinates"`
}

type CentroideResponse struct {
	Tipo        string     `json:"tipo"`
	Coordinates [2]float64 `json:"coordinates"`
}

type EspacioResponse struct {
	ID                      string              `json:"id"`
	SedeID                  string              `json:"sedeId"`
	Torre                   *string             `json:"torre,omitempty"`
	BloqueID                *string             `json:"bloqueId,omitempty"`
	Piso                    *int                `json:"piso,omitempty"`
	Codigo                  string              `json:"codigo"`
	Nombre                  string              `json:"nombre"`
	Capacidad               int                 `json:"capacidad"`
	Tipo                    geo.TipoEspacio     `json:"tipo"`
	FacultadResponsable     string              `json:"facultadResponsable,omitempty"`
	Estado                  geo.EstadoEspacio   `json:"estado"`
	NivelValidacion         geo.NivelValidacion `json:"nivelValidacion"`
	BufferMetros            float64             `json:"bufferMetros"`
	Geometria               *GeometriaResponse  `json:"geometria,omitempty"`
	AreaMetrosCuadrados     float64             `json:"areaMetrosCuadrados,omitempty"`
	Centroide               *CentroideResponse  `json:"centroide,omitempty"`
	PrecisionPromedioMetros *float64            `json:"precisionPromedioMetros,omitempty"`
	MetodoCaptura           *geo.MetodoCaptura  `json:"metodoCaptura,omitempty"`
	VersionGeometria        int                 `json:"versionGeometria"`
	Activo                  bool                `json:"activo"`
	CreadoEn                time.Time           `json:"creadoEn"`
	ActualizadoEn           time.Time           `json:"actualizadoEn"`
}

func EspacioToResponse(e *geo.Espacio) EspacioResponse {
	resp := EspacioResponse{
		ID:                      e.ID,
		SedeID:                  e.SedeID,
		Torre:                   e.Torre,
		BloqueID:                e.BloqueID,
		Piso:                    e.Piso,
		Codigo:                  e.Codigo,
		Nombre:                  e.Nombre,
		Capacidad:               e.Capacidad,
		Tipo:                    e.Tipo,
		FacultadResponsable:     e.FacultadResponsable,
		Estado:                  e.Estado,
		NivelValidacion:         e.NivelValidacion,
		BufferMetros:            e.BufferMetros,
		AreaMetrosCuadrados:     e.AreaMetrosCuadrados,
		PrecisionPromedioMetros: e.PrecisionPromedioMetros,
		MetodoCaptura:           e.MetodoCaptura,
		VersionGeometria:        e.VersionGeometria,
		Activo:                  e.Activo,
		CreadoEn:                e.CreadoEn,
		ActualizadoEn:           e.ActualizadoEn,
	}
	if e.Geometria != nil {
		resp.Geometria = &GeometriaResponse{
			Tipo:        "Polygon",
			Coordinates: [][][2]float64{e.Geometria.Coordinates()},
		}
	}
	if e.Centroide != nil {
		resp.Centroide = &CentroideResponse{
			Tipo:        "Point",
			Coordinates: e.Centroide.Coordinates(),
		}
	}
	return resp
}

// ─── SOLAPAMIENTOS (US-GEO-05) ──────────────────────────────────

type SolapamientoItemResponse struct {
	SedeID             string  `json:"sedeId"`
	BloqueID           *string `json:"bloqueId,omitempty"`
	Piso               *int    `json:"piso,omitempty"`
	Espacio1ID         string  `json:"espacio1Id"`
	Espacio1Codigo     string  `json:"espacio1Codigo"`
	Espacio1Nombre     string  `json:"espacio1Nombre"`
	Espacio2ID         string  `json:"espacio2Id"`
	Espacio2Codigo     string  `json:"espacio2Codigo"`
	Espacio2Nombre     string  `json:"espacio2Nombre"`
	AreaSolapadaM2     float64 `json:"areaSolapadaM2"`
	PorcentajeSolapado float64 `json:"porcentajeSolapado"`
	EsCritico          bool    `json:"esCritico"`
}

type InformeSolapamientosResponse struct {
	TotalConflictos int                        `json:"totalConflictos"`
	Conflictos      []SolapamientoItemResponse `json:"conflictos"`
}

// EspacioGeometriaHistResponse representa una versión archivada de la geometría de un espacio (US-GEO-06 AC-04).
type EspacioGeometriaHistResponse struct {
	ID                      string             `json:"id"`
	EspacioID               string             `json:"espacioId"`
	Version                 int                `json:"version"`
	Geometria               *GeometriaResponse `json:"geometria"`
	AreaMetrosCuadrados     float64            `json:"areaMetrosCuadrados"`
	Centroide               *CentroideResponse `json:"centroide,omitempty"`
	MetodoCaptura           *string            `json:"metodoCaptura,omitempty"`
	PrecisionPromedioMetros *float64           `json:"precisionPromedioMetros,omitempty"`
	CreadoPor               string             `json:"creadoPor"`
	CreadoEn                time.Time          `json:"creadoEn"`
	MotivoCambio            string             `json:"motivoCambio,omitempty"`
}

func EspacioGeometriaHistToResponse(h *geo.EspacioGeometriaHist) EspacioGeometriaHistResponse {
	var geom *GeometriaResponse
	coords := h.Geometria.Coordinates()
	if len(coords) > 0 {
		geom = &GeometriaResponse{
			Tipo:        "Polygon",
			Coordinates: [][][2]float64{coords},
		}
	}

	var centroide *CentroideResponse
	if h.Centroide != nil {
		centroide = &CentroideResponse{
			Tipo:        "Point",
			Coordinates: h.Centroide.Coordinates(),
		}
	}

	var metodo *string
	if h.MetodoCaptura != nil {
		m := string(*h.MetodoCaptura)
		metodo = &m
	}

	return EspacioGeometriaHistResponse{
		ID:                      h.ID,
		EspacioID:               h.EspacioID,
		Version:                 h.Version,
		Geometria:               geom,
		AreaMetrosCuadrados:     h.AreaMetrosCuadrados,
		Centroide:               centroide,
		MetodoCaptura:           metodo,
		PrecisionPromedioMetros: h.PrecisionPromedioMetros,
		CreadoPor:               h.CreadoPor,
		CreadoEn:                h.CreadoEn,
		MotivoCambio:            h.MotivoCambio,
	}
}
