// Package privacidad — solicitudes de derechos del titular (US-LEG-02, RNF-LEG-004).
// Ley 1581 de 2012, art. 14 y 15: las consultas se responden en 10 días hábiles (prorrogables 5)
// y los reclamos (rectificación, actualización, supresión) en 15 días hábiles (prorrogables 8).
package privacidad

import (
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/shared"
)

// TipoSolicitud es el derecho que ejerce el titular.
type TipoSolicitud string

const (
	SolicitudRectificacion TipoSolicitud = "RECTIFICACION"
	SolicitudSupresion     TipoSolicitud = "SUPRESION"
)

// EstadoSolicitud sigue el caso desde la radicación hasta la respuesta.
type EstadoSolicitud string

const (
	SolicitudRadicada  EstadoSolicitud = "RADICADA"
	SolicitudEnTramite EstadoSolicitud = "EN_TRAMITE"
	SolicitudAtendida  EstadoSolicitud = "ATENDIDA"
	SolicitudDenegada  EstadoSolicitud = "DENEGADA"
)

// Plazos legales en días hábiles (Ley 1581 de 2012, art. 14 y 15).
const (
	DiasHabilesConsulta         = 10
	DiasHabilesProrrogaConsulta = 5
	DiasHabilesReclamo          = 15
	DiasHabilesProrrogaReclamo  = 8
)

// CamposRectificables son los datos personales que el titular puede pedir corregir. El correo
// institucional identifica la cuenta y lo administra la institución.
var CamposRectificables = []string{"nombre", "apellido", "documento"}

// TransicionSolicitud registra cada cambio del caso con su responsable (AC-02).
type TransicionSolicitud struct {
	Estado  EstadoSolicitud `json:"estado" bson:"estado"`
	ActorID string          `json:"actorId" bson:"actorId"`
	Nota    string          `json:"nota,omitempty" bson:"nota,omitempty"`
	En      time.Time       `json:"en" bson:"en"`
}

// SolicitudDerecho es el caso radicado por el titular.
type SolicitudDerecho struct {
	ID            string                `json:"id" bson:"_id"`
	TitularID     string                `json:"titularId" bson:"titularId"`
	Tipo          TipoSolicitud         `json:"tipo" bson:"tipo"`
	Estado        EstadoSolicitud       `json:"estado" bson:"estado"`
	Descripcion   string                `json:"descripcion" bson:"descripcion"`
	Cambios       map[string]string     `json:"cambios,omitempty" bson:"cambios,omitempty"`
	Evaluacion    []ElementoSupresion   `json:"evaluacion,omitempty" bson:"evaluacion,omitempty"`
	ResponsableID string                `json:"responsableId,omitempty" bson:"responsableId,omitempty"`
	Respuesta     string                `json:"respuesta,omitempty" bson:"respuesta,omitempty"`
	RadicadaEn    time.Time             `json:"radicadaEn" bson:"radicadaEn"`
	VenceEn       time.Time             `json:"venceEn" bson:"venceEn"`
	ResueltaEn    *time.Time            `json:"resueltaEn,omitempty" bson:"resueltaEn,omitempty"`
	Historial     []TransicionSolicitud `json:"historial" bson:"historial"`
}

// NuevaSolicitud valida la radicación y fija el plazo legal del reclamo.
func NuevaSolicitud(titularID string, tipo TipoSolicitud, descripcion string, cambios map[string]string, ahora time.Time) (*SolicitudDerecho, error) {
	descripcion = strings.TrimSpace(descripcion)
	var campos []shared.FieldError
	switch tipo {
	case SolicitudRectificacion:
		cambios = cambiosValidos(cambios)
		if len(cambios) == 0 {
			campos = append(campos, shared.FieldError{Campo: "cambios", Error: "indique al menos un dato a corregir: nombre, apellido o documento"})
		}
	case SolicitudSupresion:
		cambios = nil
	default:
		campos = append(campos, shared.FieldError{Campo: "tipo", Error: "debe ser RECTIFICACION o SUPRESION"})
	}
	if len([]rune(descripcion)) < 10 {
		campos = append(campos, shared.FieldError{Campo: "descripcion", Error: "explique la solicitud (mínimo 10 caracteres)"})
	}
	if len(campos) > 0 {
		return nil, shared.NewValidationError("La solicitud no es válida", campos...)
	}
	ahora = ahora.UTC()
	return &SolicitudDerecho{
		TitularID: titularID, Tipo: tipo, Estado: SolicitudRadicada, Descripcion: descripcion, Cambios: cambios,
		RadicadaEn: ahora, VenceEn: SumarDiasHabiles(ahora, DiasHabilesReclamo),
		Historial: []TransicionSolicitud{{Estado: SolicitudRadicada, ActorID: titularID, En: ahora}},
	}, nil
}

// cambiosValidos conserva solo los campos rectificables con un valor no vacío.
func cambiosValidos(cambios map[string]string) map[string]string {
	res := map[string]string{}
	for _, c := range CamposRectificables {
		if v := strings.TrimSpace(cambios[c]); v != "" {
			res[c] = v
		}
	}
	return res
}

// Abierta indica si el caso aún espera respuesta.
func (s *SolicitudDerecho) Abierta() bool {
	return s.Estado == SolicitudRadicada || s.Estado == SolicitudEnTramite
}

// Vencida indica si el plazo legal se cumplió sin respuesta.
func (s *SolicitudDerecho) Vencida(ahora time.Time) bool {
	return s.Abierta() && ahora.After(s.VenceEn)
}

// Asignar fija el responsable del caso y lo pone en trámite.
func (s *SolicitudDerecho) Asignar(responsableID, actorID string, ahora time.Time) error {
	if !s.Abierta() {
		return errCerrada()
	}
	s.ResponsableID = responsableID
	s.Estado = SolicitudEnTramite
	s.Historial = append(s.Historial, TransicionSolicitud{Estado: SolicitudEnTramite, ActorID: actorID, Nota: "Responsable: " + responsableID, En: ahora.UTC()})
	return nil
}

// Resolver cierra el caso con la respuesta al titular; denegar exige explicar el motivo.
func (s *SolicitudDerecho) Resolver(actorID string, atendida bool, respuesta string, ahora time.Time) error {
	if !s.Abierta() {
		return errCerrada()
	}
	respuesta = strings.TrimSpace(respuesta)
	if len([]rune(respuesta)) < 10 {
		return shared.NewValidationError("La respuesta al titular es obligatoria",
			shared.FieldError{Campo: "respuesta", Error: "mínimo 10 caracteres"})
	}
	s.Estado = SolicitudDenegada
	if atendida {
		s.Estado = SolicitudAtendida
	}
	t := ahora.UTC()
	s.Respuesta, s.ResueltaEn = respuesta, &t
	if s.ResponsableID == "" {
		s.ResponsableID = actorID
	}
	s.Historial = append(s.Historial, TransicionSolicitud{Estado: s.Estado, ActorID: actorID, Nota: respuesta, En: t})
	return nil
}

func errCerrada() error {
	return &shared.DomainError{Code: shared.ErrEstadoInvalido, Message: "La solicitud ya fue resuelta"}
}

// SumarDiasHabiles cuenta días hábiles (lunes a viernes) en hora institucional y devuelve el
// final del último día. Los festivos no se descuentan: el plazo resultante nunca es más largo
// que el legal.
func SumarDiasHabiles(desde time.Time, dias int) time.Time {
	zona := shared.ZonaInstitucional()
	d := desde.In(zona)
	d = time.Date(d.Year(), d.Month(), d.Day(), 0, 0, 0, 0, zona)
	for contados := 0; contados < dias; {
		d = d.AddDate(0, 0, 1)
		if d.Weekday() != time.Saturday && d.Weekday() != time.Sunday {
			contados++
		}
	}
	return d.Add(24*time.Hour - time.Second).UTC()
}
