// Package marcaje define los tipos, entidades y motor de validación pura del SIAA.
// Satisface RN-001..RN-005, RF-MAR-001..016, §11 y T-MAR-03.1.
package marcaje

import (
	"time"

	"github.com/siaa/backend/internal/domain/geo"
)

// TipoMarcaje define si el intento corresponde a entrada o salida de sesión.
type TipoMarcaje string

const (
	TipoEntrada TipoMarcaje = "ENTRADA"
	TipoSalida  TipoMarcaje = "SALIDA"
)

// ResultadoMarcaje define los estados dictaminados por el motor determinista.
type ResultadoMarcaje string

const (
	ResultadoPresente               ResultadoMarcaje = "PRESENTE"
	ResultadoTardanza               ResultadoMarcaje = "TARDANZA"
	ResultadoPrecisionInsuficiente  ResultadoMarcaje = "PRECISION_INSUFICIENTE"
	ResultadoRechazadoFueraDeArea   ResultadoMarcaje = "RECHAZADO_FUERA_DE_AREA"
	ResultadoRechazadoFueraHorario  ResultadoMarcaje = "RECHAZADO_FUERA_DE_HORARIO"
	ResultadoRechazadoIntegridad    ResultadoMarcaje = "RECHAZADO_INTEGRIDAD"
	ResultadoRechazadoSinAsignacion ResultadoMarcaje = "RECHAZADO_SIN_ASIGNACION"
	ResultadoRechazadoVerificacion  ResultadoMarcaje = "RECHAZADO_VERIFICACION"
	ResultadoAusente                ResultadoMarcaje = "AUSENTE"

	// Alias retrocompatibles
	ResultadoValido        ResultadoMarcaje = "VALIDO"
	ResultadoRetardo       ResultadoMarcaje = "RETARDO"
	ResultadoFueraDeArea   ResultadoMarcaje = "FUERA_DE_AREA"
	ResultadoFueraDeTiempo ResultadoMarcaje = "FUERA_DE_TIEMPO"
)

// MotivoRechazo especifica la causa técnica exacta del resultado negativo.
type MotivoRechazo string

const (
	MotivoDispositivoNoVinculado    MotivoRechazo = "DISPOSITIVO_NO_VINCULADO"
	MotivoAttestationFallida        MotivoRechazo = "ATTESTATION_FALLIDA"
	MotivoSinAsignacion             MotivoRechazo = "SIN_ASIGNACION"
	MotivoFueraDeHorario            MotivoRechazo = "FUERA_DE_HORARIO"
	MotivoPrecisionInsuficiente     MotivoRechazo = "PRECISION_INSUFICIENTE"
	MotivoMockLocation              MotivoRechazo = "MOCK_LOCATION"
	MotivoDispositivoComprometido   MotivoRechazo = "DISPOSITIVO_COMPROMETIDO"
	MotivoFueraDeArea               MotivoRechazo = "FUERA_DE_AREA"
	MotivoVerificacionFallida       MotivoRechazo = "VERIFICACION_FALLIDA"
	MotivoDesfaseRelojExcesivo      MotivoRechazo = "DESFASE_RELOJ_EXCESIVO"
	MotivoVentanaEstudiantilCerrada MotivoRechazo = "VENTANA_ESTUDIANTIL_CERRADA"
)

// PasoValidacion enumera los 11 pasos deterministas del algoritmo RN-001 (§11.2).
type PasoValidacion int

const (
	PasoAutorizacion           PasoValidacion = 1
	PasoDispositivo            PasoValidacion = 2
	PasoAttestation            PasoValidacion = 3
	PasoAsignacion             PasoValidacion = 4
	PasoVentanaTemporal        PasoValidacion = 5
	PasoPrecision              PasoValidacion = 6
	PasoIntegridadUbicacion    PasoValidacion = 7
	PasoContencionGeoespacial  PasoValidacion = 8
	PasoVerificacionComplement PasoValidacion = 9
	PasoIdempotencia           PasoValidacion = 10
	PasoClasificacion          PasoValidacion = 11
)

// RolMarcaje define si quien marca lo hace en calidad de docente o de estudiante.
type RolMarcaje string

const (
	RolDocente    RolMarcaje = "DOCENTE"
	RolEstudiante RolMarcaje = "ESTUDIANTE"
)

// OrigenMarcaje identifica el canal de procedencia del registro.
type OrigenMarcaje string

const (
	OrigenAppMovil        OrigenMarcaje = "APP_MOVIL"
	OrigenOffline         OrigenMarcaje = "OFFLINE"
	OrigenManual          OrigenMarcaje = "MANUAL"
	OrigenManualDocente   OrigenMarcaje = "MANUAL_DOCENTE"
	OrigenSistemaAusencia OrigenMarcaje = "SISTEMA_AUSENCIA"
)

// IntegridadDispositivo contiene las señales de seguridad levantadas por el cliente móvil.
type IntegridadDispositivo struct {
	MockLocation     bool   `json:"mockLocation"`
	Rooteado         bool   `json:"rooteado"`
	Emulador         bool   `json:"emulador"`
	AttestationOk    bool   `json:"attestationOk"`
	AttestationToken string `json:"attestationToken,omitempty"`
}

// VerificacionEntrada contiene el valor de verificación complementaria (BSSID, BLE o QR).
type VerificacionEntrada struct {
	Metodo string `json:"metodo"` // WIFI, BLE, QR
	Valor  string `json:"valor"`
}

// SolicitudMarcaje contiene todos los datos aportados por la petición del cliente.
type SolicitudMarcaje struct {
	SesionID                   string                `json:"sesionId"`
	UsuarioID                  string                `json:"usuarioId"`
	RolMarcaje                 RolMarcaje            `json:"rolMarcaje"`
	Tipo                       TipoMarcaje           `json:"tipo"`
	Latitud                    float64               `json:"latitud"`
	Longitud                   float64               `json:"longitud"`
	PrecisionMetros            float64               `json:"precisionMetros"`
	TimestampDispositivo       time.Time             `json:"timestampDispositivo"`
	DispositivoID              string                `json:"dispositivoId"`
	ModeloDispositivo          string                `json:"modeloDispositivo,omitempty"`
	SODispositivo              string                `json:"soDispositivo,omitempty"`
	VersionApp                 string                `json:"versionApp"`
	Integridad                 IntegridadDispositivo `json:"integridad"`
	VerificacionComplementaria *VerificacionEntrada  `json:"verificacionComplementaria,omitempty"`
	IdempotencyKey             string                `json:"idempotencyKey"`
	Origen                     OrigenMarcaje         `json:"origen"`
}

// SesionInfo contiene la información mínima requerida de la sesión académica para evaluar.
type SesionInfo struct {
	ID                        string
	EspacioID                 string
	EspacioCodigo             string
	DocenteIDs                []string
	SuplenteID                string
	EstudianteIDs             []string
	InicioProgramado          time.Time
	FinProgramado             time.Time
	Modalidad                 string // PRESENCIAL, VIRTUAL
	VentanaEstudiantilAbierta bool
	VentanaEstudiantilCierra  time.Time
}

// ParametrosMarcaje contiene los parámetros efectivos congelados aplicables al marcaje.
type ParametrosMarcaje struct {
	HolguraEntradaAntesMin   int
	HolguraEntradaDespuesMin int
	HolguraSalidaAntesMin    int
	HolguraSalidaDespuesMin  int
	PrecisionGpsMaxMetros    float64
	UmbralTardanzaMin        int
	ExigirAttestation        bool
	BloquearMockLocation     bool
	BloquearRooteado         bool
	DesfaseRelojMaxSegundos  int
	MarcajeSalidaModo        string // OBLIGATORIO, OPCIONAL, DESACTIVADO
}

// ContextoSesion agrupa todo el contexto pre-resuelto por el caso de uso antes de invocar el motor puro.
type ContextoSesion struct {
	Sesion                     *SesionInfo
	DispositivoVinculadoID     string
	Parametros                 ParametrosMarcaje
	Geometria                  geo.GeoPolygon
	GeometriaBuffer            geo.GeoPolygon
	VerificacionExigida        bool
	ValoresVerificacionValidos []string
	MarcajePrevio              *Marcaje
	UsuarioActivo              bool
	TienePermiso               bool
}

// ResultadoEvaluacion representa el dictamen exhaustivo emitido por el motor de validación.
type ResultadoEvaluacion struct {
	Resultado             ResultadoMarcaje `json:"resultado"`
	MotivoRechazo         MotivoRechazo    `json:"motivoRechazo,omitempty"`
	PasoFallido           PasoValidacion   `json:"pasoFallido,omitempty"`
	Mensaje               string           `json:"mensaje"`
	DistanciaMetros       float64          `json:"distanciaMetros,omitempty"`
	MinutosRespectoInicio int              `json:"minutosRespectoInicio"`
	MinutosDesviacion     int              `json:"minutosDesviacion,omitempty"`
	PrecisionRecibida     float64          `json:"precisionRecibida,omitempty"`
	PrecisionRequerida    float64          `json:"precisionRequerida,omitempty"`
	PermiteReintento      bool             `json:"permiteReintento"`
	PuedeJustificar       bool             `json:"puedeJustificar"`
	DesfaseRelojSegundos  int              `json:"desfaseRelojSegundos"`
	EsAnomalia            bool             `json:"esAnomalia"`
	MarcajeExistenteID    string           `json:"marcajeExistenteId,omitempty"`
}
