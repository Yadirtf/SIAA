package academico

import (
	"context"
	"fmt"
	"strings"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
)

// planFila es lo que se aplicará por una fila válida: IDs resueltos y la asignación a crear.
type planFila struct {
	fila       *FilaImportacionAcademica
	periodo    *domainAca.Periodo
	asignatura *domainAca.Asignatura
	grupo      *domainAca.Grupo // nil = se crea al aplicar
	asignacion *domainAca.Asignacion
}

// claveGrupo identifica un grupo aún no creado (mismo número, asignatura y periodo).
func (p *planFila) claveGrupo() string {
	return p.asignatura.ID() + "|" + p.periodo.ID() + "|" + p.fila.GrupoCodigo
}

// validarFilas resuelve cada fila contra la base (AC-04) y reporta todas las colisiones,
// contra lo ya programado y dentro del propio archivo (AC-05), sin persistir nada (AC-01).
func (s *Service) validarFilas(ctx context.Context, actor ContextoActor, filas []FilaImportacionAcademica) []*planFila {
	cat := s.nuevoCatalogo(ctx)
	planes := make([]*planFila, 0, len(filas))
	for i := range filas {
		f := &filas[i]
		if !f.Valida {
			continue
		}
		if p := s.resolverFila(ctx, cat, actor, f); p != nil {
			planes = append(planes, p)
		}
	}
	return detectarColisionesLote(cat, ctx, planes)
}

func (s *Service) resolverFila(ctx context.Context, cat *catalogoImportacion, actor ContextoActor, f *FilaImportacionAcademica) *planFila {
	periodo := cat.periodos[f.PeriodoCodigo]
	if periodo == nil {
		f.error("El periodo '" + f.PeriodoCodigo + "' no existe")
	} else if err := periodo.PuedeModificar(); err != nil {
		f.error("El periodo '" + f.PeriodoCodigo + "' no admite cambios: " + err.Error())
	}
	var programa *domainAca.Programa
	if f.ProgramaCodigo != "" {
		if programa = cat.programas[f.ProgramaCodigo]; programa == nil {
			f.error("El programa '" + f.ProgramaCodigo + "' no existe")
		}
	}
	asignatura, msg := cat.asignatura(f.AsignaturaCodigo, programa)
	if msg != "" && (f.ProgramaCodigo == "" || programa != nil) {
		f.error(msg)
	}
	facultadID := ""
	if asignatura != nil {
		if prog := cat.programasID[asignatura.ProgramaID()]; prog != nil {
			facultadID = prog.FacultadID()
		}
		if fac := cat.facultades[f.FacultadCodigo]; f.FacultadCodigo != "" && (fac == nil || fac.ID() != facultadID) {
			f.error("La facultad '" + f.FacultadCodigo + "' no existe o no corresponde al programa de la asignatura")
		}
	}
	docente := cat.docente(ctx, f.DocenteDocumento)
	nombreDocente := ""
	switch {
	case docente == nil || docente.Eliminado:
		f.error("El docente '" + f.DocenteDocumento + "' no existe (use su documento o correo)")
	case !docente.Activo:
		f.error("El docente '" + f.DocenteDocumento + "' está inactivo")
	case !tieneRol(docente.Roles, rbac.RolDocente):
		f.error("El usuario '" + f.DocenteDocumento + "' no tiene el rol DOCENTE")
	default:
		nombreDocente = strings.TrimSpace(docente.Nombre + " " + docente.Apellido)
	}
	var aula *geo.Espacio
	if f.AulaCodigo != "" && f.Modalidad != "VIRTUAL" {
		aula = s.validarAulaImportada(ctx, cat, f, periodo)
	}
	franja, adv, err := domainAca.NuevaFranjaHoraria(f.DiaSemana, f.HoraInicio, f.HoraFin, "")
	if err != nil {
		f.error(fmt.Sprintf("Franja horaria inválida (%s - %s): %v", f.HoraInicio, f.HoraFin, err))
	}
	for _, a := range adv {
		f.advertir(a)
	}
	if !f.Valida || periodo == nil || asignatura == nil {
		return nil
	}
	if !actor.permiteFacultad(facultadID, periodo.SedeID()) {
		f.error("La asignatura '" + f.AsignaturaCodigo + "' está fuera de tu alcance")
		return nil
	}
	p := &planFila{fila: f, periodo: periodo, asignatura: asignatura,
		grupo: cat.grupo(ctx, asignatura.ID(), periodo.ID(), f.GrupoCodigo)}
	grupoID := "nuevo:" + p.claveGrupo()
	if p.grupo != nil {
		grupoID = p.grupo.ID()
	} else {
		f.advertir("Se creará el grupo '" + f.GrupoCodigo + "' de la asignatura '" + f.AsignaturaCodigo + "'")
	}
	espacioID, espacioNombre := "", ""
	if aula != nil {
		espacioID, espacioNombre = aula.ID, strings.TrimSpace(aula.Codigo+" · "+aula.Nombre)
	}
	asig, err := domainAca.NuevaAsignacion(shared.NewID(), periodo.ID(), []string{docente.ID}, nombreDocente,
		grupoID, asignatura.ID(), facultadID, espacioID, espacioNombre, franja,
		domainAca.ModalidadAsignacion(f.Modalidad), nil, periodo.FechaInicio(), periodo.FechaFin(), nil, s.clk.Now())
	if err != nil {
		f.error("No se puede construir la asignación: " + err.Error())
		return nil
	}
	p.asignacion = asig
	return p
}

func (s *Service) validarAulaImportada(ctx context.Context, cat *catalogoImportacion, f *FilaImportacionAcademica, periodo *domainAca.Periodo) *geo.Espacio {
	aula := cat.aula(ctx, f.AulaCodigo)
	switch {
	case aula == nil:
		f.error("El aula '" + f.AulaCodigo + "' no existe")
		return nil
	case aula.Estado == geo.EstadoInactivo:
		f.error("El aula '" + f.AulaCodigo + "' está inactiva")
		return nil
	case periodo != nil && periodo.SedeID() != "" && aula.SedeID != periodo.SedeID():
		f.error("El aula '" + f.AulaCodigo + "' no pertenece a la sede del periodo")
		return nil
	}
	if aula.Geometria == nil || len(aula.Geometria.Coordinates()) == 0 {
		f.advertir("El aula '" + f.AulaCodigo + "' no tiene geometría levantada; las sesiones no podrán validarse espacialmente (US-ACA-03 AC-04)")
	}
	return aula
}

// detectarColisionesLote marca en cada fila todas sus colisiones; las filas que chocan
// quedan inválidas y no entran al plan.
func detectarColisionesLote(cat *catalogoImportacion, ctx context.Context, planes []*planFila) []*planFila {
	aceptados := make([]*planFila, 0, len(planes))
	for _, p := range planes {
		existentes := cat.existentes(ctx, p.periodo.ID())
		if rep := domainAca.DetectarColisiones(existentes, *p.asignacion); rep != nil {
			p.fila.error(describirColision(rep, "una asignación ya programada"))
		}
		if mismo := mismoGrupoSolapado(existentes, p.asignacion); mismo {
			p.fila.error("El grupo ya tiene una clase programada que se cruza con esta franja")
		}
		for _, previo := range aceptados {
			if previo.periodo.ID() != p.periodo.ID() {
				continue
			}
			ref := fmt.Sprintf("la fila %d del archivo", previo.fila.NumeroFila)
			if rep := domainAca.DetectarColisiones([]domainAca.Asignacion{*previo.asignacion}, *p.asignacion); rep != nil {
				p.fila.error(describirColision(rep, ref))
			} else if previo.asignacion.GrupoID() == p.asignacion.GrupoID() && previo.asignacion.Franja().SeSolapaCon(p.asignacion.Franja()) {
				p.fila.error("Duplica o se cruza con " + ref + " para el mismo grupo")
			}
		}
		if p.fila.Valida {
			aceptados = append(aceptados, p)
		}
	}
	return aceptados
}

func mismoGrupoSolapado(existentes []domainAca.Asignacion, nueva *domainAca.Asignacion) bool {
	for _, e := range existentes {
		if !e.Borrado() && e.Estado() == domainAca.AsignacionActiva && e.GrupoID() == nueva.GrupoID() && e.Franja().SeSolapaCon(nueva.Franja()) {
			return true
		}
	}
	return false
}

func describirColision(rep *domainAca.ReporteColision, con string) string {
	franja := fmt.Sprintf("%s %s a %s", nombreDia(rep.DiaSemana), rep.HoraInicio, rep.HoraFin)
	if rep.Tipo == domainAca.ColisionAula {
		return "Choque de aula con " + con + " (" + franja + ")"
	}
	return "Choque de docente con " + con + " (" + franja + ")"
}

func tieneRol(roles []user.RolAsignado, rol rbac.RoleName) bool {
	for _, r := range roles {
		if r.Nombre == rol {
			return true
		}
	}
	return false
}
