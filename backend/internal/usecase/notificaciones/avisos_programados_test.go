package notificaciones

import (
	"context"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/justificacion"
	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
)

// colaDedupe rechaza las claves repetidas, como el índice único de MongoDB.
type colaDedupe struct {
	fakeCola
	claves map[string]bool
}

func (c *colaDedupe) Encolar(ctx context.Context, n *notificacion.Notificacion) (bool, error) {
	if c.claves == nil {
		c.claves = map[string]bool{}
	}
	if c.claves[n.ClaveDedupe] {
		return false, nil
	}
	c.claves[n.ClaveDedupe] = true
	return c.fakeCola.Encolar(ctx, n)
}

// usuariosPorRol responde Buscar por rol y FindByID desde un mapa.
type usuariosPorRol struct {
	repository.UsuarioRepository
	porRol  map[string][]*user.Usuario
	porID   map[string]*user.Usuario
	filtros []repository.FiltroUsuarios
}

func (u *usuariosPorRol) Buscar(_ context.Context, f repository.FiltroUsuarios) ([]*user.Usuario, int64, error) {
	u.filtros = append(u.filtros, f)
	l := u.porRol[f.Rol]
	return l, int64(len(l)), nil
}
func (u *usuariosPorRol) FindByID(_ context.Context, id string) (*user.Usuario, error) {
	return u.porID[id], nil
}

type pendientesFijas struct {
	lista  []*justificacion.Justificacion
	limite time.Time
}

func (p *pendientesFijas) SinResolver(_ context.Context, antes time.Time, _ int) ([]*justificacion.Justificacion, error) {
	p.limite = antes
	return p.lista, nil
}

func TestRecordatorioRevision_UnaVezPorRevisor(t *testing.T) {
	ahora := time.Date(2026, 10, 9, 15, 0, 0, 0, time.UTC)
	cola := &colaDedupe{}
	usuarios := &usuariosPorRol{porRol: map[string][]*user.Usuario{
		string(rbac.RolCoordinador): {{ID: "coord-1"}, {ID: "doc-1"}},
	}}
	pend := &pendientesFijas{lista: []*justificacion.Justificacion{
		{ID: "j1", DocenteID: "doc-1", Estado: justificacion.EstadoRadicada, FacultadID: "fac-1", NombreSesion: "Cálculo"},
		{ID: "j2", DocenteID: "doc-2", Estado: justificacion.EstadoEnRevision, RevisorID: "rev-9"},
	}}
	r := NewRecordatorioRevision(pend, usuarios, NewProductor(cola, nil, nil))
	n, err := r.EjecutarCiclo(context.Background(), ahora)
	if err != nil || n != 2 {
		t.Fatalf("primer ciclo: %d %v", n, err)
	}
	if !pend.limite.Equal(ahora.Add(-48 * time.Hour)) {
		t.Fatalf("plazo por defecto de 48 h: %v", pend.limite)
	}
	if cola.encolados[0].UsuarioID != "coord-1" || cola.encolados[1].UsuarioID != "rev-9" {
		t.Fatalf("destinatarios: %+v %+v", cola.encolados[0], cola.encolados[1])
	}
	if cola.encolados[0].Tipo != notificacion.TipoRecordatorioRevision || cola.encolados[0].Datos["justificacionId"] != "j1" {
		t.Fatalf("aviso: %+v", cola.encolados[0])
	}
	if f := usuarios.filtros[0]; f.Visibilidad == nil || f.Visibilidad.AmbitoIDs[0] != "fac-1" {
		t.Fatalf("debe buscar coordinadores de la facultad: %+v", f)
	}
	// AC-02: el recordatorio no se repite en los ciclos siguientes.
	if n, _ := r.EjecutarCiclo(context.Background(), ahora.Add(time.Hour)); n != 0 || len(cola.encolados) != 2 {
		t.Fatalf("el recordatorio debe salir una sola vez: %d", n)
	}
	r.ConPlazoHoras(24)
	_, _ = r.EjecutarCiclo(context.Background(), ahora)
	if !pend.limite.Equal(ahora.Add(-24 * time.Hour)) {
		t.Fatalf("plazo configurado: %v", pend.limite)
	}
}

func TestRecordatorioRevision_SinCoordinadoresAvisaAdministracion(t *testing.T) {
	cola := &colaDedupe{}
	usuarios := &usuariosPorRol{porRol: map[string][]*user.Usuario{string(rbac.RolAdminInst): {{ID: "admin-1"}}}}
	pend := &pendientesFijas{lista: []*justificacion.Justificacion{{ID: "j1", DocenteID: "d", Estado: justificacion.EstadoRadicada, SedeID: "s"}}}
	n, _ := NewRecordatorioRevision(pend, usuarios, NewProductor(cola, nil, nil)).EjecutarCiclo(context.Background(), time.Now())
	if n != 1 || cola.encolados[0].UsuarioID != "admin-1" {
		t.Fatalf("sin coordinadores responde la administración: %d %+v", n, cola.encolados)
	}
}

type rolesFijos struct{ lista []*user.Usuario }

func (r *rolesFijos) ConRolesPorVencer(context.Context, time.Time, time.Time) ([]*user.Usuario, error) {
	return r.lista, nil
}

func TestAvisoVencimientoRoles_TresDiasAntesUnaVez(t *testing.T) {
	ahora := time.Date(2026, 10, 9, 15, 0, 0, 0, time.UTC)
	pronto, lejos := ahora.Add(48*time.Hour), ahora.Add(10*24*time.Hour)
	titular := &user.Usuario{ID: "u1", Nombre: "Ana", Apellido: "Gómez", Roles: []user.RolAsignado{
		{Nombre: rbac.RolCoordinador, VigenciaFin: &pronto, AsignadoPor: "admin-1"},
		{Nombre: rbac.RolDocente},
		{Nombre: rbac.RolMonitor, VigenciaFin: &lejos, AsignadoPor: "admin-1"},
	}}
	usuarios := &usuariosPorRol{porID: map[string]*user.Usuario{"admin-1": {ID: "admin-1", Activo: true}}}
	cola := &colaDedupe{}
	a := NewAvisoVencimientoRoles(&rolesFijos{lista: []*user.Usuario{titular}}, usuarios, NewProductor(cola, nil, nil))
	n, err := a.EjecutarCiclo(context.Background(), ahora)
	if err != nil || n != 1 {
		t.Fatalf("solo el rol que vence en 3 días se avisa: %d %v", n, err)
	}
	aviso := cola.encolados[0]
	if aviso.UsuarioID != "admin-1" || aviso.Tipo != notificacion.TipoVencimientoRol || aviso.Datos["rol"] != "COORDINADOR" {
		t.Fatalf("aviso al administrador que asignó el rol: %+v", aviso)
	}
	if n, _ := a.EjecutarCiclo(context.Background(), ahora.Add(time.Hour)); n != 0 {
		t.Fatalf("el aviso sale una sola vez por vencimiento: %d", n)
	}
	// Si quien asignó ya no está activo, responde la administración institucional.
	usuarios.porID["admin-1"].Activo = false
	usuarios.porRol = map[string][]*user.Usuario{string(rbac.RolAdminInst): {{ID: "admin-2"}}}
	if n, _ := a.EjecutarCiclo(context.Background(), ahora); n != 1 || cola.encolados[1].UsuarioID != "admin-2" {
		t.Fatalf("respaldo en la administración: %d", n)
	}
}
