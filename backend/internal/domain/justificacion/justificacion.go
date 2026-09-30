// Package justificacion modela las novedades que un docente radica sobre una sesión
// ausente o rechazada y su flujo de aprobación (EP-07, RF-JUS-001..005).
package justificacion

import (
	"errors"
	"strings"
	"time"
)

// Tipo tipifica la novedad (RF-JUS-003).
type Tipo string

const (
	TipoIncapacidad  Tipo = "INCAPACIDAD"
	TipoComision     Tipo = "COMISION"
	TipoPermiso      Tipo = "PERMISO"
	TipoFallaTecnica Tipo = "FALLA_TECNICA"
	TipoCalamidad    Tipo = "CALAMIDAD"
)

// Estado del flujo RADICADA → EN_REVISION → APROBADA / RECHAZADA (RF-JUS-002).
type Estado string

const (
	EstadoRadicada   Estado = "RADICADA"
	EstadoEnRevision Estado = "EN_REVISION"
	EstadoAprobada   Estado = "APROBADA"
	EstadoRechazada  Estado = "RECHAZADA"
)

// Longitudes mínimas de los textos libres para que la novedad sea revisable.
const (
	MinDescripcion   = 10
	MinObservaciones = 10
)

var (
	ErrTipoInvalido          = errors.New("tipo de novedad inválido")
	ErrDescripcionCorta      = errors.New("la descripción debe tener al menos 10 caracteres")
	ErrObservacionesCortas   = errors.New("las observaciones deben tener al menos 10 caracteres")
	ErrTransicionInvalida    = errors.New("la justificación no admite ese cambio de estado")
	ErrRevisorEsSolicitante  = errors.New("quien radica una justificación no puede revisarla")
	ErrSinSoporte            = errors.New("la justificación requiere al menos un soporte")
	ErrEstadoDestinoInvalido = errors.New("estado de destino inválido")
)

// Adjunto describe un soporte; el contenido cifrado se guarda aparte.
type Adjunto struct {
	ID     string `json:"id" bson:"id"`
	Nombre string `json:"nombre" bson:"nombre"`
	Mime   string `json:"mime" bson:"mime"`
	Tamano int64  `json:"tamano" bson:"tamano"`
	SHA256 string `json:"sha256" bson:"sha256"`
}

// Transicion registra cada cambio de estado con su responsable.
type Transicion struct {
	Estado        Estado    `json:"estado" bson:"estado"`
	ActorID       string    `json:"actorId" bson:"actorId"`
	Observaciones string    `json:"observaciones,omitempty" bson:"observaciones,omitempty"`
	En            time.Time `json:"en" bson:"en"`
}

// Justificacion es la novedad radicada sobre una sesión.
type Justificacion struct {
	ID            string       `json:"id" bson:"_id"`
	SesionID      string       `json:"sesionId" bson:"sesionId"`
	DocenteID     string       `json:"docenteId" bson:"docenteId"`
	Tipo          Tipo         `json:"tipo" bson:"tipo"`
	Descripcion   string       `json:"descripcion" bson:"descripcion"`
	Estado        Estado       `json:"estado" bson:"estado"`
	Adjuntos      []Adjunto    `json:"adjuntos" bson:"adjuntos"`
	RevisorID     string       `json:"revisorId,omitempty" bson:"revisorId,omitempty"`
	Observaciones string       `json:"observaciones,omitempty" bson:"observaciones,omitempty"`
	Historial     []Transicion `json:"historial" bson:"historial"`
	SedeID        string       `json:"sedeId,omitempty" bson:"sedeId"`
	FacultadID    string       `json:"facultadId,omitempty" bson:"facultadId"`
	// Datos de la sesión copiados para listar sin consultas adicionales.
	FechaSesion   string    `json:"fechaSesion" bson:"fechaSesion"`
	NombreSesion  string    `json:"nombreSesion,omitempty" bson:"nombreSesion,omitempty"`
	CreadoEn      time.Time `json:"creadoEn" bson:"creadoEn"`
	ActualizadoEn time.Time `json:"actualizadoEn" bson:"actualizadoEn"`
}

// TipoValido indica si el tipo pertenece al catálogo de RF-JUS-003.
func TipoValido(t Tipo) bool {
	switch t {
	case TipoIncapacidad, TipoComision, TipoPermiso, TipoFallaTecnica, TipoCalamidad:
		return true
	}
	return false
}

// Nueva valida los datos de radicación y crea la justificación en estado RADICADA.
func Nueva(sesionID, docenteID string, tipo Tipo, descripcion string, adjuntos []Adjunto, ahora time.Time) (*Justificacion, error) {
	if !TipoValido(tipo) {
		return nil, ErrTipoInvalido
	}
	descripcion = strings.TrimSpace(descripcion)
	if len([]rune(descripcion)) < MinDescripcion {
		return nil, ErrDescripcionCorta
	}
	if len(adjuntos) == 0 {
		return nil, ErrSinSoporte
	}
	return &Justificacion{
		SesionID:      sesionID,
		DocenteID:     docenteID,
		Tipo:          tipo,
		Descripcion:   descripcion,
		Estado:        EstadoRadicada,
		Adjuntos:      adjuntos,
		Historial:     []Transicion{{Estado: EstadoRadicada, ActorID: docenteID, En: ahora}},
		CreadoEn:      ahora,
		ActualizadoEn: ahora,
	}, nil
}

// Vigente indica si la justificación sigue en curso o fue aprobada; una rechazada
// permite radicar otra sobre la misma sesión.
func (j *Justificacion) Vigente() bool {
	return j.Estado != EstadoRechazada
}

// Aprobada indica si la novedad justifica la sesión en los reportes (RF-JUS-004).
func (j *Justificacion) Aprobada() bool { return j.Estado == EstadoAprobada }

// Transitar aplica el cambio de estado con responsable y observaciones (RF-JUS-002).
// Pasar a EN_REVISION es opcional: se puede decidir directamente desde RADICADA.
func (j *Justificacion) Transitar(destino Estado, actorID, observaciones string, ahora time.Time) error {
	if actorID == j.DocenteID {
		return ErrRevisorEsSolicitante
	}
	observaciones = strings.TrimSpace(observaciones)
	switch destino {
	case EstadoEnRevision:
		if j.Estado != EstadoRadicada {
			return ErrTransicionInvalida
		}
	case EstadoAprobada, EstadoRechazada:
		if j.Estado != EstadoRadicada && j.Estado != EstadoEnRevision {
			return ErrTransicionInvalida
		}
		// Rechazar exige explicar el motivo al solicitante.
		if destino == EstadoRechazada && len([]rune(observaciones)) < MinObservaciones {
			return ErrObservacionesCortas
		}
		j.Observaciones = observaciones
	default:
		return ErrEstadoDestinoInvalido
	}
	j.Estado = destino
	j.RevisorID = actorID
	j.ActualizadoEn = ahora
	j.Historial = append(j.Historial, Transicion{Estado: destino, ActorID: actorID, Observaciones: observaciones, En: ahora})
	return nil
}
