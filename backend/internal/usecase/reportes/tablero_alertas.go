package reportes

import (
	"context"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

const (
	// diasAlertasActivas: una alerta de inasistencias más antigua ya no se muestra en el tablero.
	diasAlertasActivas = 7
	// maxAlertasLeidas acota la lectura de avisos (hay uno por coordinador destinatario).
	maxAlertasLeidas = 500
)

// AlertaActiva es una racha de inasistencias consecutivas de un docente que sigue abierta:
// el motor de alertas (US-PAR-04) la notificó y el docente no ha vuelto a registrar una
// entrada válida desde entonces.
type AlertaActiva struct {
	DocenteID  string    `json:"docenteId"`
	Docente    string    `json:"docente"`
	Mensaje    string    `json:"mensaje"`
	SesionID   string    `json:"sesionInicioRachaId"` // primera sesión de la racha
	FacultadID string    `json:"facultadId,omitempty"`
	CreadaEn   time.Time `json:"creadaEn"`
}

// alertasActivas lee los avisos ALERTA_INASISTENCIAS de los últimos días (índice por tipo y
// fecha), los agrupa por racha (llegan uno por coordinador), aplica el ámbito del actor según
// la facultad y sede de la sesión que inició la racha, y descarta las rachas ya cerradas.
func (t *TableroService) alertasActivas(ctx context.Context, n *nombres, actor Actor, facultadID string, ahora time.Time) ([]AlertaActiva, error) {
	res := []AlertaActiva{}
	if t.alertas == nil {
		return res, nil
	}
	avisos, err := t.alertas.Recientes(ctx, notificacion.TipoAlertaInasistencias,
		ahora.AddDate(0, 0, -diasAlertasActivas), maxAlertasLeidas)
	if err != nil {
		return nil, err
	}
	vistas := map[string]bool{}
	for _, a := range avisos {
		docenteID, sesionID, ok := rachaDeAviso(a)
		if !ok || vistas[docenteID+":"+sesionID] {
			continue
		}
		vistas[docenteID+":"+sesionID] = true
		inicio, err := t.sesiones.FindByID(ctx, sesionID)
		if err != nil || inicio == nil || !alertaEnAlcance(actor, facultadID, inicio) {
			continue
		}
		cerrada, err := t.rachaCerrada(ctx, docenteID, a.CreadaEn)
		if err != nil {
			return nil, err
		}
		if cerrada {
			continue
		}
		res = append(res, AlertaActiva{
			DocenteID: docenteID, Docente: n.usuario(ctx, docenteID), Mensaje: a.Cuerpo,
			SesionID: sesionID, FacultadID: inicio.FacultadID(), CreadaEn: a.CreadaEn,
		})
	}
	return res, nil
}

// rachaDeAviso extrae docente y sesión de inicio de la clave "inasistencias:<docente>:<sesion>:<coordinador>".
func rachaDeAviso(a *notificacion.Notificacion) (docenteID, sesionID string, ok bool) {
	partes := strings.Split(strings.TrimPrefix(a.ClaveDedupe, "inasistencias:"), ":")
	if len(partes) < 2 || partes[0] == "" || partes[1] == "" {
		return "", "", false
	}
	return partes[0], partes[1], true
}

// alertaEnAlcance aplica el ámbito del actor (RF-ROL-003) y el filtro de facultad opcional.
func alertaEnAlcance(actor Actor, facultadID string, s *academico.Sesion) bool {
	if facultadID != "" && s.FacultadID() != facultadID {
		return false
	}
	if actor.Alcance.Global {
		return true
	}
	return actor.Alcance.PermiteRegistroDe("", s.FacultadID(), s.SedeID()) ||
		(actor.Alcance.SoloPropios && s.TieneDocente(actor.Alcance.UsuarioID))
}

// rachaCerrada indica si el docente registró una entrada válida después del aviso. Consulta
// solo sus sesiones desde la fecha del aviso (índice por docente) y sus marcajes por sesionId.
func (t *TableroService) rachaCerrada(ctx context.Context, docenteID string, desde time.Time) (bool, error) {
	sesiones, err := t.sesiones.List(ctx, repository.SesionFilter{DocenteID: docenteID, FechaDesde: shared.FechaLocal(desde)})
	if err != nil {
		return false, err
	}
	ids := make([]string, len(sesiones))
	for i, s := range sesiones {
		ids[i] = s.ID()
	}
	entradas, err := t.marcajes.ListarConsolidados(ctx, ids, marcaje.TipoEntrada)
	if err != nil {
		return false, err
	}
	for _, m := range entradas {
		if (m.UsuarioID == docenteID || m.DocenteID == docenteID) && m.EsExitoso() && m.TimestampServidor.After(desde) {
			return true, nil
		}
	}
	return false, nil
}
