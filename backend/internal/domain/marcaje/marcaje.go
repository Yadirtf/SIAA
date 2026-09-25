// Package marcaje define la entidad de persistencia y evidencia técnica inmutable.
// Satisface US-MAR-04 (AC-01..AC-05), US-MAR-05, US-MAR-09, RF-AUD-004.
package marcaje

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrTipoInvalido       = errors.New("tipo de marcaje inválido")
	ErrCoordenadasNulas   = errors.New("las coordenadas no pueden ser nulas")
	ErrDocenteRequerido   = errors.New("el docente o usuario es obligatorio")
	ErrSesionRequerida    = errors.New("la sesión es obligatoria")
	ErrPrecisionExcesiva  = errors.New("la precisión GPS supera el umbral permitido")
	ErrMotivoInsuficiente = errors.New("el motivo de ajuste debe tener al menos 20 caracteres")
)

// TelemetriaGPS contiene la información de posición capturada durante el marcaje.
type TelemetriaGPS struct {
	Coordenadas           []float64 `json:"coordenadas" bson:"coordenadas"` // [longitud, latitud] GeoJSON
	PrecisionMetros       float64   `json:"precisionMetros" bson:"precisionMetros"`
	MetodoCaptura         string    `json:"metodoCaptura" bson:"metodoCaptura"`
	MockLocationDetectado bool      `json:"mockLocationDetectado" bson:"mockLocationDetectado"`
}

// DispositivoMarcaje contiene los metadatos y banderas de seguridad del dispositivo emisor.
type DispositivoMarcaje struct {
	ID            string `json:"id" bson:"id"`
	Modelo        string `json:"modelo,omitempty" bson:"modelo,omitempty"`
	SO            string `json:"so,omitempty" bson:"so,omitempty"`
	VersionApp    string `json:"versionApp" bson:"versionApp"`
	Rooteado      bool   `json:"rooteado" bson:"rooteado"`
	Emulador      bool   `json:"emulador" bson:"emulador"`
	AttestationOk bool   `json:"attestationOk" bson:"attestationOk"`
}

// Marcaje representa la evidencia completa e inmutable de asistencia de una sesión.
type Marcaje struct {
	ID                     string               `json:"id" bson:"_id,omitempty"`
	SesionID               string               `json:"sesionId" bson:"sesionId"`
	UsuarioID              string               `json:"usuarioId" bson:"usuarioId"`
	DocenteID              string               `json:"docenteId,omitempty" bson:"docenteId,omitempty"` // alias para retrocompatibilidad
	EspacioID              string               `json:"espacioId,omitempty" bson:"espacioId,omitempty"`
	RolMarcaje             RolMarcaje           `json:"rolMarcaje" bson:"rolMarcaje"`
	Tipo                   TipoMarcaje          `json:"tipo" bson:"tipo"`
	Resultado              ResultadoMarcaje     `json:"resultado" bson:"resultado"`
	MotivoRechazo          string               `json:"motivoRechazo,omitempty" bson:"motivoRechazo,omitempty"`
	PasoFallido            PasoValidacion       `json:"pasoFallido,omitempty" bson:"pasoFallido,omitempty"`
	Geolocalizacion        TelemetriaGPS        `json:"geolocalizacion" bson:"geolocalizacion"`
	Dispositivo            DispositivoMarcaje   `json:"dispositivo" bson:"dispositivo"`
	DistanciaMetros        float64              `json:"distanciaMetros" bson:"distanciaMetros"`
	ContenidoEnBuffer      bool                 `json:"contenidoEnBuffer" bson:"contenidoEnBuffer"`
	TimestampServidor      time.Time            `json:"timestampServidor" bson:"timestampServidor"`
	TimestampDispositivo   time.Time            `json:"timestampDispositivo" bson:"timestampDispositivo"`
	Timestamp              time.Time            `json:"timestamp" bson:"timestamp"` // alias retrocompatible
	DesfaseRelojSegundos   int                  `json:"desfaseRelojSegundos" bson:"desfaseRelojSegundos"`
	MinutosRespectoInicio  int                  `json:"minutosRespectoInicio" bson:"minutosRespectoInicio"`
	DiferenciaMinutos      int                  `json:"diferenciaMinutos" bson:"diferenciaMinutos"` // alias retrocompatible
	VerificacionComplement *VerificacionEntrada `json:"verificacionComplementaria,omitempty" bson:"verificacionComplementaria,omitempty"`
	Origen                 OrigenMarcaje        `json:"origen" bson:"origen"`
	Anulado                bool                 `json:"anulado" bson:"anulado"`
	MotivoAjuste           string               `json:"motivoAjuste,omitempty" bson:"motivoAjuste,omitempty"`
	AjustadoPor            string               `json:"ajustadoPor,omitempty" bson:"ajustadoPor,omitempty"`
	AjustadoEn             *time.Time           `json:"ajustadoEn,omitempty" bson:"ajustadoEn,omitempty"`
	EsAnomalia             bool                 `json:"esAnomalia" bson:"esAnomalia"`
	IdempotencyKey         string               `json:"idempotencyKey,omitempty" bson:"idempotencyKey,omitempty"`
	CreadoEn               time.Time            `json:"creadoEn" bson:"creadoEn"`
}

// ValidarEstructura valida las invariantes de negocio de un intento o registro de marcaje.
func (m *Marcaje) ValidarEstructura() error {
	user := strings.TrimSpace(m.UsuarioID)
	if user == "" {
		user = strings.TrimSpace(m.DocenteID)
	}
	if user == "" {
		return ErrDocenteRequerido
	}
	if strings.TrimSpace(m.SesionID) == "" {
		return ErrSesionRequerida
	}
	if m.Tipo != TipoEntrada && m.Tipo != TipoSalida {
		return ErrTipoInvalido
	}
	// Si no es modalidad virtual ni origen manual, se exigen coordenadas GeoJSON válidas [lon, lat]
	if m.Origen != OrigenManual && m.Origen != OrigenManualDocente && m.Origen != OrigenSistemaAusencia {
		if len(m.Geolocalizacion.Coordenadas) != 2 {
			return ErrCoordenadasNulas
		}
	}
	return nil
}

// EsExitoso indica si el marcaje cuenta como asistencia válida (con o sin retardo).
func (m *Marcaje) EsExitoso() bool {
	return m.Resultado == ResultadoPresente ||
		m.Resultado == ResultadoTardanza ||
		m.Resultado == ResultadoValido ||
		m.Resultado == ResultadoRetardo
}

// RequiereJustificacion indica si el resultado fue un rechazo que habilita justificación posterior (EP-07).
func (m *Marcaje) RequiereJustificacion() bool {
	return m.Resultado == ResultadoRechazadoFueraDeArea ||
		m.Resultado == ResultadoRechazadoFueraHorario ||
		m.Resultado == ResultadoFueraDeArea ||
		m.Resultado == ResultadoFueraDeTiempo ||
		m.Resultado == ResultadoAusente
}

// EsAnulable determina si el registro se encuentra activo para ser ajustado o anulado.
func (m *Marcaje) EsAnulable() bool {
	return !m.Anulado
}
