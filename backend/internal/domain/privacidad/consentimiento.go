// Package privacidad modela el consentimiento informado para el tratamiento de la ubicación
// (Ley 1581 de 2012, RNF-LEG-001, US-LEG-01). ADR-02: sin dependencias de infraestructura.
package privacidad

import "time"

// Decision es la respuesta del titular frente a una versión de la política.
type Decision string

const (
	DecisionAceptado  Decision = "ACEPTADO"
	DecisionRechazado Decision = "RECHAZADO"
)

// Consentimiento registra una decisión con su versión, fecha y dispositivo (US-LEG-01 AC-02).
// Cada decisión es un registro nuevo: el historial completo sirve de prueba ante el titular.
type Consentimiento struct {
	ID            string
	UsuarioID     string
	Version       string
	Decision      Decision
	DispositivoID string
	IPOrigen      string
	DecididoEn    time.Time
}

// Politica es el aviso de privacidad y la política de tratamiento vigentes (RNF-LEG-003).
type Politica struct {
	Version       string `json:"version"`
	Contenido     string `json:"contenido"`
	ActualizadaEn string `json:"actualizadaEn"`
	Institucion   string `json:"institucion"`
	Contacto      string `json:"contacto"`
}

// Estado resume la situación del titular frente a la versión vigente.
type Estado struct {
	VersionVigente     string     `json:"versionVigente"`
	RequiereAceptacion bool       `json:"requiereAceptacion"`
	Decision           *Decision  `json:"decision"`
	VersionDecidida    *string    `json:"versionDecidida"`
	DecididoEn         *time.Time `json:"decididoEn"`
}

// CalcularEstado exige aceptar de nuevo cuando cambia la versión (US-LEG-01 AC-03): solo una
// aceptación de la versión vigente habilita el marcaje.
func CalcularEstado(vigente string, ultimo *Consentimiento) Estado {
	e := Estado{VersionVigente: vigente, RequiereAceptacion: true}
	if ultimo == nil {
		return e
	}
	d, v, en := ultimo.Decision, ultimo.Version, ultimo.DecididoEn
	e.Decision, e.VersionDecidida, e.DecididoEn = &d, &v, &en
	e.RequiereAceptacion = !(ultimo.Version == vigente && ultimo.Decision == DecisionAceptado)
	return e
}

// PermiteMarcar indica si el titular aceptó la política vigente (US-LEG-01 AC-05).
func (e Estado) PermiteMarcar() bool {
	return !e.RequiereAceptacion
}
