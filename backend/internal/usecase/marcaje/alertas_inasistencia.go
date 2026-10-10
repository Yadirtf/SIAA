// Package marcaje — alerta temprana por inasistencias consecutivas del docente.
// US-PAR-04 AC-02: al alcanzar el umbral inasistencias_consecutivas_alerta se avisa al
// coordinador de la facultad. AC-03: la alerta se emite una vez por racha; las ausencias
// siguientes de la misma racha quedan agrupadas en ella.
package marcaje

import (
	"context"
	"sort"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	dompar "github.com/siaa/backend/internal/domain/parametro"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/repository"
)

// AvisoInasistencias encola el aviso al coordinador (lo implementa el productor de notificaciones).
type AvisoInasistencias interface {
	AlertaInasistencias(ctx context.Context, coordinadorID, docenteID, nombreDocente string, conteo, umbral int, claveRacha string)
}

// AlertasInasistencias evalúa la racha de ausencias de un docente y avisa a su coordinación.
type AlertasInasistencias struct {
	sesiones repository.SesionRepository
	marcajes repository.MarcajeRepository
	usuarios repository.UsuarioRepository
	aviso    AvisoInasistencias
	// umbral resuelve inasistencias_consecutivas_alerta para la facultad (cascada de parámetros).
	umbral func(ctx context.Context, facultadID string) int
}

// NewAlertasInasistencias crea el evaluador de alertas.
func NewAlertasInasistencias(s repository.SesionRepository, m repository.MarcajeRepository, u repository.UsuarioRepository,
	aviso AvisoInasistencias, umbral func(ctx context.Context, facultadID string) int) *AlertasInasistencias {
	return &AlertasInasistencias{sesiones: s, marcajes: m, usuarios: u, aviso: aviso, umbral: umbral}
}

// Racha es el resultado de contar ausencias consecutivas hacia atrás desde la última sesión.
type Racha struct {
	Consecutivas int
	Totales      int
	Asistidas    int
	InicioID     string // primera sesión de la racha: identifica la racha para agrupar avisos
}

// Evaluar cuenta la racha del docente en la facultad y, si alcanza el umbral, avisa a cada
// coordinador con ámbito en esa facultad. Devuelve cuántos avisos se encolaron.
func (a *AlertasInasistencias) Evaluar(ctx context.Context, docenteID, facultadID string, ahora time.Time) int {
	racha, err := a.racha(ctx, docenteID, facultadID, ahora)
	if err != nil || racha.Consecutivas == 0 {
		return 0
	}
	umbral := 3
	if a.umbral != nil {
		umbral = a.umbral(ctx, facultadID)
	}
	alertas := dompar.EvaluarAlertasAsistencia(docenteID, facultadID, "", "", racha.Totales, racha.Asistidas,
		racha.Consecutivas, map[dompar.Clave]interface{}{dompar.ClaveInasistenciasConsecutivasAlerta: umbral},
		dompar.HistorialAlertasDocente{})
	emitir := false
	for _, al := range alertas {
		emitir = emitir || al.Tipo == dompar.AlertaInasistenciasConsecutivas
	}
	if !emitir || a.aviso == nil {
		return 0
	}
	nombre := a.nombre(ctx, docenteID)
	enviados := 0
	for _, coordinador := range a.coordinadores(ctx, facultadID) {
		a.aviso.AlertaInasistencias(ctx, coordinador, docenteID, nombre, racha.Consecutivas, umbral, docenteID+":"+racha.InicioID)
		enviados++
	}
	return enviados
}

// racha recorre las sesiones ya terminadas del docente en la facultad, de la más reciente a la
// más antigua, y cuenta las que no tienen entrada válida hasta encontrar una asistida.
func (a *AlertasInasistencias) racha(ctx context.Context, docenteID, facultadID string, ahora time.Time) (Racha, error) {
	todas, err := a.sesiones.List(ctx, repository.SesionFilter{DocenteID: docenteID, FacultadID: facultadID})
	if err != nil {
		return Racha{}, err
	}
	var pasadas []*academico.Sesion
	for _, s := range todas {
		if s.Estado() == academico.EstadoSesionCancelada || s.Estado() == academico.EstadoSesionExcluida || s.FinProgramado().After(ahora) {
			continue
		}
		pasadas = append(pasadas, s)
	}
	sort.Slice(pasadas, func(i, j int) bool { return pasadas[i].InicioProgramado().After(pasadas[j].InicioProgramado()) })
	ids := make([]string, len(pasadas))
	for i, s := range pasadas {
		ids[i] = s.ID()
	}
	entradas, err := a.marcajes.ListarConsolidados(ctx, ids, domainMarcaje.TipoEntrada)
	if err != nil {
		return Racha{}, err
	}
	asistio := map[string]bool{}
	for _, m := range entradas {
		if (m.UsuarioID == docenteID || m.DocenteID == docenteID) && m.EsExitoso() {
			asistio[m.SesionID] = true
		}
	}
	r := Racha{Totales: len(pasadas)}
	enRacha := true
	for _, s := range pasadas {
		if asistio[s.ID()] {
			r.Asistidas++
			enRacha = false
			continue
		}
		if enRacha {
			r.Consecutivas++
			r.InicioID = s.ID()
		}
	}
	return r, nil
}

// coordinadores devuelve los coordinadores activos con ámbito en la facultad.
func (a *AlertasInasistencias) coordinadores(ctx context.Context, facultadID string) []string {
	if a.usuarios == nil || facultadID == "" {
		return nil
	}
	activo := true
	lista, _, err := a.usuarios.Buscar(ctx, repository.FiltroUsuarios{
		Rol: string(rbac.RolCoordinador), Activo: &activo, Limite: 100,
		Visibilidad: &repository.VisibilidadUsuarios{AmbitoIDs: []string{facultadID}},
	})
	if err != nil {
		return nil
	}
	ids := make([]string, 0, len(lista))
	for _, u := range lista {
		ids = append(ids, u.ID)
	}
	return ids
}

func (a *AlertasInasistencias) nombre(ctx context.Context, docenteID string) string {
	if a.usuarios != nil {
		if u, err := a.usuarios.FindByID(ctx, docenteID); err == nil && u != nil {
			return strings.TrimSpace(u.Nombre + " " + u.Apellido)
		}
	}
	return "Un docente"
}
