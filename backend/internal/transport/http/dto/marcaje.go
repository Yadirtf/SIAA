// Package dto — Data Transfer Objects para endpoints de marcaje de asistencia.
// Satisface contratos de §9.4, §9.5 y US-MAR-01..US-MAR-15.
package dto

import (
	"time"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
)

// IntegridadDTO representa las señales de seguridad emitidas por la app móvil.
type IntegridadDTO struct {
	MockLocation     bool   `json:"mockLocation"`
	Rooteado         bool   `json:"rooteado"`
	Emulador         bool   `json:"emulador"`
	AttestationOk    bool   `json:"attestationOk"`
	AttestationToken string `json:"attestationToken,omitempty"`
}

// VerificacionComplementariaDTO contiene el testigo QR o de red institucional.
type VerificacionComplementariaDTO struct {
	Metodo string `json:"metodo"` // WIFI, BLE, QR
	Valor  string `json:"valor"`
}

// CrearMarcajeRequest representa el cuerpo de POST /api/v1/marcajes (§9.4).
type CrearMarcajeRequest struct {
	SesionID                   string                         `json:"sesionId" binding:"required"`
	Tipo                       string                         `json:"tipo" binding:"required"` // ENTRADA | SALIDA
	Latitud                    float64                        `json:"latitud"`
	Longitud                   float64                        `json:"longitud"`
	PrecisionMetros            float64                        `json:"precisionMetros"`
	TimestampDispositivo       time.Time                      `json:"timestampDispositivo" binding:"required"`
	DispositivoID              string                         `json:"dispositivoId" binding:"required"`
	ModeloDispositivo          string                         `json:"modeloDispositivo,omitempty"`
	SODispositivo              string                         `json:"soDispositivo,omitempty"`
	VersionApp                 string                         `json:"versionApp" binding:"required"`
	Integridad                 IntegridadDTO                  `json:"integridad"`
	VerificacionComplementaria *VerificacionComplementariaDTO `json:"verificacionComplementaria,omitempty"`
	IdempotencyKey             string                         `json:"idempotencyKey,omitempty"`
}

// MarcajeResponse representa la respuesta JSON estructurada de evaluación y registro (§9.4).
type MarcajeResponse struct {
	MarcajeID             string   `json:"marcajeId,omitempty"`
	Resultado             string   `json:"resultado"`
	MotivoRechazo         string   `json:"motivoRechazo,omitempty"`
	Mensaje               string   `json:"mensaje"`
	DistanciaMetros       *float64 `json:"distanciaMetros,omitempty"`
	MinutosRespectoInicio int      `json:"minutosRespectoInicio,omitempty"`
	PrecisionRecibida     *float64 `json:"precisionRecibida,omitempty"`
	PrecisionRequerida    *float64 `json:"precisionRequerida,omitempty"`
	TimestampServidor     string   `json:"timestampServidor,omitempty"`
	PasoFallido           int      `json:"pasoFallido,omitempty"`
	PermiteReintento      bool     `json:"permiteReintento"`
	PuedeJustificar       bool     `json:"puedeJustificar"`
}

// SyncMarcajesRequest representa el lote de marcajes offline para POST /api/v1/marcajes/sync.
type SyncMarcajesRequest struct {
	Items []CrearMarcajeRequest `json:"items" binding:"required"`
}

// AjusteMarcajeRequest contiene los parámetros para corrección o anulación administrativa (US-MAR-09).
type AjusteMarcajeRequest struct {
	Accion         string `json:"accion"` // ANULAR | AJUSTAR
	NuevoResultado string `json:"nuevoResultado,omitempty"`
	Anulado        bool   `json:"anulado"`
	Motivo         string `json:"motivo" binding:"required"` // Mínimo 20 caracteres
}

// MarcajeManualRequest contiene los datos para creación manual de respaldo (US-MAR-09 AC-04).
type MarcajeManualRequest struct {
	SesionID  string `json:"sesionId" binding:"required"`
	UsuarioID string `json:"usuarioId" binding:"required"`
	Tipo      string `json:"tipo" binding:"required"` // ENTRADA | SALIDA
	Resultado string `json:"resultado" binding:"required"`
	Motivo    string `json:"motivo" binding:"required"` // Mínimo 20 caracteres
}

// VentanaEstudiantilRequest define la duración de apertura de ventana grupal (US-MAR-13).
type VentanaEstudiantilRequest struct {
	DuracionMinutos int `json:"duracionMinutos"`
}

// ItemListaManualDTO representa el registro de un estudiante en la lista manual (US-MAR-14).
type ItemListaManualDTO struct {
	EstudianteID string `json:"estudianteId" binding:"required"`
	Presente     bool   `json:"presente"`
}

// ListaManualRequest representa el cuerpo de POST /sesiones/:id/lista-manual (US-MAR-14).
type ListaManualRequest struct {
	Motivo      string               `json:"motivo" binding:"required"`
	Estudiantes []ItemListaManualDTO `json:"estudiantes" binding:"required"`
}

// ToDomain convierte la petición DTO a la estructura limpia de dominio SolicitudMarcaje.
func (r *CrearMarcajeRequest) ToDomain(usuarioID string) domainMarcaje.SolicitudMarcaje {
	tipo := domainMarcaje.TipoEntrada
	if r.Tipo == string(domainMarcaje.TipoSalida) {
		tipo = domainMarcaje.TipoSalida
	}

	var verif *domainMarcaje.VerificacionEntrada
	if r.VerificacionComplementaria != nil {
		verif = &domainMarcaje.VerificacionEntrada{
			Metodo: r.VerificacionComplementaria.Metodo,
			Valor:  r.VerificacionComplementaria.Valor,
		}
	}

	return domainMarcaje.SolicitudMarcaje{
		SesionID:             r.SesionID,
		UsuarioID:            usuarioID,
		RolMarcaje:           domainMarcaje.RolDocente,
		Tipo:                 tipo,
		Latitud:              r.Latitud,
		Longitud:             r.Longitud,
		PrecisionMetros:      r.PrecisionMetros,
		TimestampDispositivo: r.TimestampDispositivo,
		DispositivoID:        r.DispositivoID,
		ModeloDispositivo:    r.ModeloDispositivo,
		SODispositivo:        r.SODispositivo,
		VersionApp:           r.VersionApp,
		Integridad: domainMarcaje.IntegridadDispositivo{
			MockLocation:     r.Integridad.MockLocation,
			Rooteado:         r.Integridad.Rooteado,
			Emulador:         r.Integridad.Emulador,
			AttestationOk:    r.Integridad.AttestationOk,
			AttestationToken: r.Integridad.AttestationToken,
		},
		VerificacionComplementaria: verif,
		IdempotencyKey:             r.IdempotencyKey,
	}
}
