// Package geo — tipos y comandos para los casos de uso de jerarquía física y cartografía.
package geo

import (
	"github.com/siaa/backend/internal/domain/geo"
)

// ContextoActor contiene información del usuario que invoca la operación para auditoría.
type ContextoActor struct {
	ActorID       string
	RolActivo     string
	CorrelationID string
	IPOrigen      string
	AgenteUsuario string
}

// CrearSedeCmd contiene los datos para registrar una sede.
type CrearSedeCmd struct {
	Codigo    string
	Nombre    string
	Direccion string
	Actor     ContextoActor
}

// CrearBloqueCmd contiene los datos para registrar un bloque en una sede.
type CrearBloqueCmd struct {
	SedeID string
	Codigo string
	Nombre string
	Pisos  []int
	Actor  ContextoActor
}

// CrearEspacioCmd contiene los datos para registrar un espacio físico.
// AC-02: sede y espacio obligatorios; torre, bloque y piso opcionales.
type CrearEspacioCmd struct {
	SedeID              string
	Torre               *string
	BloqueID            *string
	Piso                *int
	Codigo              string
	Nombre              string
	Capacidad           int
	Tipo                geo.TipoEspacio
	FacultadResponsable string
	Estado              geo.EstadoEspacio
	NivelValidacion     geo.NivelValidacion
	BufferMetros        float64
	Actor               ContextoActor
}

// ActualizarEspacioCmd contiene los datos para modificar un espacio.
// AC-05: si se pasa a INACTIVO o MANTENIMIENTO con sesiones futuras, ConfirmarImpacto debe ser true.
type ActualizarEspacioCmd struct {
	SedeID              *string
	Torre               *string
	BloqueID            *string
	Piso                *int
	Codigo              *string
	Nombre              *string
	Capacidad           *int
	Tipo                *geo.TipoEspacio
	FacultadResponsable *string
	Estado              *geo.EstadoEspacio
	NivelValidacion     *geo.NivelValidacion
	BufferMetros        *float64
	ConfirmarImpacto    bool
	Actor               ContextoActor
}

// GuardarGeometriaCmd contiene los parámetros para actualizar la geometría de un espacio.
// T-GEO-02.7, AC-06, AC-07, RF-GEO-002, US-GEO-05.
type GuardarGeometriaCmd struct {
	EspacioID               string
	Vertices                []geo.GeoPoint
	MetodoCaptura           geo.MetodoCaptura
	PrecisionPromedioMetros *float64
	ConfirmarSolapamiento   bool
	MotivoSolapamiento      string
	Actor                   ContextoActor
}

// ItemInformeSolapamiento representa un conflicto de solapamiento entre dos espacios en el informe general.
// US-GEO-05, AC-04, T-GEO-05.3.
type ItemInformeSolapamiento struct {
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
	EsCritico          bool    `json:"esCritico"` // true si > 50%
}

