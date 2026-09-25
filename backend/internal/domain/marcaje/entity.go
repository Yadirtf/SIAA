// Package marcaje define las entidades de dominio y reglas del motor de marcaje.
// Satisface la arquitectura de dominio del SIAA y RNF-MAN-001 (cobertura >= 90%).
package marcaje

import (
	"errors"
	"strings"
	"time"
)

// TipoMarcaje define si el registro corresponde a entrada o salida de clase.
type TipoMarcaje string

const (
	TipoEntrada TipoMarcaje = "ENTRADA"
	TipoSalida  TipoMarcaje = "SALIDA"
)

// ResultadoMarcaje define los estados posibles dictaminados por el motor de validación.
type ResultadoMarcaje string

const (
	ResultadoValido                 ResultadoMarcaje = "VALIDO"
	ResultadoRetardo                ResultadoMarcaje = "RETARDO"
	ResultadoFueraDeArea            ResultadoMarcaje = "FUERA_DE_AREA"
	ResultadoFueraDeTiempo          ResultadoMarcaje = "FUERA_DE_TIEMPO"
	ResultadoRechazadoIntegridad    ResultadoMarcaje = "RECHAZADO_INTEGRIDAD"
	ResultadoRechazadoSinAsignacion ResultadoMarcaje = "RECHAZADO_SIN_ASIGNACION"
	ResultadoRechazadoVerificacion  ResultadoMarcaje = "RECHAZADO_VERIFICACION"
)

var (
	ErrTipoInvalido      = errors.New("tipo de marcaje inválido")
	ErrCoordenadasNulas  = errors.New("las coordenadas no pueden ser nulas")
	ErrDocenteRequerido  = errors.New("el docente es obligatorio")
	ErrSesionRequerida   = errors.New("la sesión es obligatoria")
	ErrPrecisionExcesiva = errors.New("la precisión GPS supera el umbral permitido")
)

// TelemetriaGPS contiene la información de posición capturada durante el marcaje.
type TelemetriaGPS struct {
	Coordenadas           []float64 `json:"coordenadas"` // [longitud, latitud] GeoJSON
	PrecisionMetros       float64   `json:"precisionMetros"`
	MetodoCaptura         string    `json:"metodoCaptura"`
	MockLocationDetectado bool      `json:"mockLocationDetectado"`
}

// DispositivoMarcaje contiene los metadatos del dispositivo confiable emisor.
type DispositivoMarcaje struct {
	ID         string `json:"id"`
	Modelo     string `json:"modelo"`
	SO         string `json:"so"`
	VersionApp string `json:"versionApp"`
}

// Marcaje representa la evidencia inmutable de asistencia de una sesión.
type Marcaje struct {
	ID                string             `json:"id" bson:"_id,omitempty"`
	SesionID          string             `json:"sesionId" bson:"sesionId"`
	DocenteID         string             `json:"docenteId" bson:"docenteId"`
	Tipo              TipoMarcaje        `json:"tipo" bson:"tipo"`
	Timestamp         time.Time          `json:"timestamp" bson:"timestamp"`
	Geolocalizacion   TelemetriaGPS      `json:"geolocalizacion" bson:"geolocalizacion"`
	Resultado         ResultadoMarcaje   `json:"resultado" bson:"resultado"`
	MotivoRechazo     string             `json:"motivoRechazo,omitempty" bson:"motivoRechazo,omitempty"`
	Dispositivo       DispositivoMarcaje `json:"dispositivo" bson:"dispositivo"`
	DistanciaMetros   float64            `json:"distanciaMetros" bson:"distanciaMetros"`
	DiferenciaMinutos int                `json:"diferenciaMinutos" bson:"diferenciaMinutos"`
}

// ValidarEstructura valida las invariantes de negocio de un intento de marcaje.
func (m *Marcaje) ValidarEstructura() error {
	if strings.TrimSpace(m.DocenteID) == "" {
		return ErrDocenteRequerido
	}
	if strings.TrimSpace(m.SesionID) == "" {
		return ErrSesionRequerida
	}
	if m.Tipo != TipoEntrada && m.Tipo != TipoSalida {
		return ErrTipoInvalido
	}
	if len(m.Geolocalizacion.Coordenadas) != 2 {
		return ErrCoordenadasNulas
	}
	return nil
}

// EsExitoso indica si el marcaje cuenta como asistencia válida (con o sin retardo).
func (m *Marcaje) EsExitoso() bool {
	return m.Resultado == ResultadoValido || m.Resultado == ResultadoRetardo
}

// RequiereJustificacion indica si el resultado fue un rechazo que habilita justificación posterior.
func (m *Marcaje) RequiereJustificacion() bool {
	return m.Resultado == ResultadoFueraDeArea || m.Resultado == ResultadoFueraDeTiempo
}
