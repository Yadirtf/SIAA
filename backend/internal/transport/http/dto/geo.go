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
	SedeID              string            `json:"sedeId" validate:"required"`
	Torre               *string           `json:"torre,omitempty"`
	BloqueID            *string           `json:"bloqueId,omitempty"`
	Piso                *int              `json:"piso,omitempty"`
	Codigo              string            `json:"codigo" validate:"required"`
	Nombre              string            `json:"nombre" validate:"required"`
	Capacidad           int               `json:"capacidad"`
	Tipo                geo.TipoEspacio   `json:"tipo" validate:"required"`
	FacultadResponsable string            `json:"facultadResponsable,omitempty"`
	Estado              geo.EstadoEspacio `json:"estado,omitempty"`
	NivelValidacion     geo.NivelValidacion `json:"nivelValidacion,omitempty"`
	BufferMetros        float64           `json:"bufferMetros,omitempty"`
}

type ActualizarEspacioRequest struct {
	SedeID              *string             `json:"sedeId,omitempty"`
	Torre               *string             `json:"torre,omitempty"`
	BloqueID            *string             `json:"bloqueId,omitempty"`
	Piso                *int                `json:"piso,omitempty"`
	Codigo              *string             `json:"codigo,omitempty"`
	Nombre              *string             `json:"nombre,omitempty"`
	Capacidad           *int                `json:"capacidad,omitempty"`
	Tipo                *geo.TipoEspacio    `json:"tipo,omitempty"`
	FacultadResponsable *string             `json:"facultadResponsable,omitempty"`
	Estado              *geo.EstadoEspacio  `json:"estado,omitempty"`
	NivelValidacion     *geo.NivelValidacion `json:"nivelValidacion,omitempty"`
	BufferMetros        *float64            `json:"bufferMetros,omitempty"`
	ConfirmarImpacto    bool                `json:"confirmarImpacto,omitempty"`
}

type EspacioResponse struct {
	ID                  string              `json:"id"`
	SedeID              string              `json:"sedeId"`
	Torre               *string             `json:"torre,omitempty"`
	BloqueID            *string             `json:"bloqueId,omitempty"`
	Piso                *int                `json:"piso,omitempty"`
	Codigo              string              `json:"codigo"`
	Nombre              string              `json:"nombre"`
	Capacidad           int                 `json:"capacidad"`
	Tipo                geo.TipoEspacio     `json:"tipo"`
	FacultadResponsable string              `json:"facultadResponsable,omitempty"`
	Estado              geo.EstadoEspacio   `json:"estado"`
	NivelValidacion     geo.NivelValidacion `json:"nivelValidacion"`
	BufferMetros        float64             `json:"bufferMetros"`
	VersionGeometria    int                 `json:"versionGeometria"`
	Activo              bool                `json:"activo"`
	CreadoEn            time.Time           `json:"creadoEn"`
	ActualizadoEn       time.Time           `json:"actualizadoEn"`
}

func EspacioToResponse(e *geo.Espacio) EspacioResponse {
	return EspacioResponse{
		ID:                  e.ID,
		SedeID:              e.SedeID,
		Torre:               e.Torre,
		BloqueID:            e.BloqueID,
		Piso:                e.Piso,
		Codigo:              e.Codigo,
		Nombre:              e.Nombre,
		Capacidad:           e.Capacidad,
		Tipo:                e.Tipo,
		FacultadResponsable: e.FacultadResponsable,
		Estado:              e.Estado,
		NivelValidacion:     e.NivelValidacion,
		BufferMetros:        e.BufferMetros,
		VersionGeometria:    e.VersionGeometria,
		Activo:              e.Activo,
		CreadoEn:            e.CreadoEn,
		ActualizadoEn:       e.ActualizadoEn,
	}
}
