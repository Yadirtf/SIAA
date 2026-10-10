// Package privacidad — suspensión de la retención por investigación en curso (US-AUD-04 AC-03).
// Mientras una investigación marcada sobre un usuario, una sesión o un marcaje siga activa,
// sus marcajes no se anonimizan aunque venza el plazo de retención (RNF-LEG-006).
package privacidad

import (
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/domain/shared"
)

// AlcanceInvestigacion indica sobre qué registros recae la suspensión.
type AlcanceInvestigacion string

const (
	AlcanceUsuario AlcanceInvestigacion = "USUARIO" // todos los marcajes del usuario
	AlcanceSesion  AlcanceInvestigacion = "SESION"  // todos los marcajes de la sesión de clase
	AlcanceMarcaje AlcanceInvestigacion = "MARCAJE" // un marcaje concreto
)

// TipoAvisoRetencionSuspendida es el aviso que recibe quien marcó la investigación cuando el
// plazo vence y la anonimización se suspende.
const TipoAvisoRetencionSuspendida notificacion.Tipo = "RETENCION_SUSPENDIDA"

// Investigacion es una marca de retención: impide anonimizar los registros que abarca.
type Investigacion struct {
	ID          string
	Alcance     AlcanceInvestigacion
	ObjetivoID  string
	Motivo      string
	CreadaPor   string
	CreadaEn    time.Time
	LiberadaPor string
	LiberadaEn  *time.Time
}

// NuevaInvestigacion valida y crea la marca sobre un registro.
func NuevaInvestigacion(alcance AlcanceInvestigacion, objetivoID, motivo, actorID string, ahora time.Time) (*Investigacion, error) {
	var campos []shared.FieldError
	switch alcance {
	case AlcanceUsuario, AlcanceSesion, AlcanceMarcaje:
	default:
		campos = append(campos, shared.FieldError{Campo: "alcance", Error: "debe ser USUARIO, SESION o MARCAJE"})
	}
	if strings.TrimSpace(objetivoID) == "" {
		campos = append(campos, shared.FieldError{Campo: "objetivoId", Error: "es obligatorio"})
	}
	if len(strings.TrimSpace(motivo)) < 5 {
		campos = append(campos, shared.FieldError{Campo: "motivo", Error: "describa la investigación (mínimo 5 caracteres)"})
	}
	if len(campos) > 0 {
		return nil, shared.NewValidationError("La investigación no es válida", campos...)
	}
	return &Investigacion{
		Alcance: alcance, ObjetivoID: strings.TrimSpace(objetivoID), Motivo: strings.TrimSpace(motivo),
		CreadaPor: actorID, CreadaEn: ahora.UTC(),
	}, nil
}

// Activa indica si la investigación sigue suspendiendo la retención.
func (i *Investigacion) Activa() bool { return i.LiberadaEn == nil }

// Liberar cierra la investigación; desde entonces sus registros siguen la retención normal.
func (i *Investigacion) Liberar(actorID string, ahora time.Time) error {
	if !i.Activa() {
		return &shared.DomainError{Code: shared.ErrEstadoInvalido, Message: "La investigación ya fue liberada"}
	}
	t := ahora.UTC()
	i.LiberadaEn, i.LiberadaPor = &t, actorID
	return nil
}

// ExclusionRetencion agrupa los registros que la anonimización no puede tocar.
type ExclusionRetencion struct {
	UsuarioIDs []string
	SesionIDs  []string
	MarcajeIDs []string
}

// Vacia indica que no hay registros protegidos.
func (e ExclusionRetencion) Vacia() bool {
	return len(e.UsuarioIDs) == 0 && len(e.SesionIDs) == 0 && len(e.MarcajeIDs) == 0
}

// ExclusionDe reúne los registros protegidos por las investigaciones dadas.
func ExclusionDe(investigaciones ...*Investigacion) ExclusionRetencion {
	var ex ExclusionRetencion
	for _, i := range investigaciones {
		if i == nil || !i.Activa() {
			continue
		}
		switch i.Alcance {
		case AlcanceUsuario:
			ex.UsuarioIDs = append(ex.UsuarioIDs, i.ObjetivoID)
		case AlcanceSesion:
			ex.SesionIDs = append(ex.SesionIDs, i.ObjetivoID)
		case AlcanceMarcaje:
			ex.MarcajeIDs = append(ex.MarcajeIDs, i.ObjetivoID)
		}
	}
	return ex
}
