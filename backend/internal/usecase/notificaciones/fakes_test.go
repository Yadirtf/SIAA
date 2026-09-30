package notificaciones

import (
	"context"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	domainGeo "github.com/siaa/backend/internal/domain/geo"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
)

// fakeCola simula la cola de avisos en memoria.
type fakeCola struct {
	encolados    []*notificacion.Notificacion
	pendientes   []*notificacion.Notificacion
	actualizados []*notificacion.Notificacion
	bandeja      []*notificacion.Notificacion
	limiteBand   int
	leidaOK      bool
	errPend      error
	errAct       error
	errBandeja   error
	errLeida     error
}

func (f *fakeCola) Encolar(_ context.Context, n *notificacion.Notificacion) (bool, error) {
	f.encolados = append(f.encolados, n)
	return true, nil
}
func (f *fakeCola) Pendientes(context.Context, time.Time, int) ([]*notificacion.Notificacion, error) {
	return f.pendientes, f.errPend
}
func (f *fakeCola) Actualizar(_ context.Context, n *notificacion.Notificacion) error {
	f.actualizados = append(f.actualizados, n)
	return f.errAct
}
func (f *fakeCola) Bandeja(_ context.Context, _ string, limite int) ([]*notificacion.Notificacion, error) {
	f.limiteBand = limite
	return f.bandeja, f.errBandeja
}
func (f *fakeCola) MarcarLeida(context.Context, string, string) (bool, error) {
	return f.leidaOK, f.errLeida
}

// fakeTokens guarda tokens push por usuario.
type fakeTokens struct {
	tokens     []repository.TokenPush
	guardados  []repository.TokenPush
	eliminados []string
	errListar  error
}

func (f *fakeTokens) Guardar(_ context.Context, t repository.TokenPush) error {
	f.guardados = append(f.guardados, t)
	return nil
}
func (f *fakeTokens) Eliminar(_ context.Context, token string) error {
	f.eliminados = append(f.eliminados, token)
	return nil
}
func (f *fakeTokens) ListarPorUsuario(_ context.Context, usuarioID string) ([]repository.TokenPush, error) {
	var out []repository.TokenPush
	for _, t := range f.tokens {
		if t.UsuarioID == usuarioID {
			out = append(out, t)
		}
	}
	return out, f.errListar
}

// fakePrefs devuelve las preferencias configuradas (nil = nunca configuradas).
type fakePrefs struct {
	pref      *notificacion.Preferencias
	guardadas *notificacion.Preferencias
	err       error
}

func (f *fakePrefs) Obtener(context.Context, string) (*notificacion.Preferencias, error) {
	if f.pref == nil {
		return nil, f.err
	}
	p := *f.pref
	return &p, f.err
}
func (f *fakePrefs) Guardar(_ context.Context, _ string, p notificacion.Preferencias) error {
	f.guardadas = &p
	return f.err
}

// fakeUsuarios solo implementa FindByID.
type fakeUsuarios struct {
	repository.UsuarioRepository
	u *user.Usuario
}

func (f *fakeUsuarios) FindByID(context.Context, string) (*user.Usuario, error) { return f.u, nil }

// fakeDispositivos solo implementa FindByInstalacion.
type fakeDispositivos struct {
	repository.DispositivoRepository
	porInstalacion map[string]*user.Dispositivo
}

func (f *fakeDispositivos) FindByInstalacion(_ context.Context, _, id string) (*user.Dispositivo, error) {
	return f.porInstalacion[id], nil
}

// fakePush responde con el error configurado por token.
type fakePush struct {
	errores map[string]error
	envios  []string
}

func (f *fakePush) Enviar(_ context.Context, token string, _ *notificacion.Notificacion) error {
	f.envios = append(f.envios, token)
	return f.errores[token]
}

// fakeCorreo registra los correos enviados.
type fakeCorreo struct {
	para, asunto []string
	err          error
}

func (f *fakeCorreo) Enviar(_ context.Context, para, asunto, _ string) error {
	f.para = append(f.para, para)
	f.asunto = append(f.asunto, asunto)
	return f.err
}

// fakeAgenda devuelve sesiones fijas y registra las ventanas consultadas.
type fakeAgenda struct {
	inician, cierran             []*academico.Sesion
	errInician, errCierran       error
	ventanaInicio, ventanaCierre [2]time.Time
}

func (f *fakeAgenda) SesionesQueInician(_ context.Context, desde, hasta time.Time) ([]*academico.Sesion, error) {
	f.ventanaInicio = [2]time.Time{desde, hasta}
	return f.inician, f.errInician
}
func (f *fakeAgenda) SesionesQueCierran(_ context.Context, desde, hasta time.Time) ([]*academico.Sesion, error) {
	f.ventanaCierre = [2]time.Time{desde, hasta}
	return f.cierran, f.errCierran
}

// fakeMarcajes solo implementa ListarConsolidados.
type fakeMarcajes struct {
	repository.MarcajeRepository
	consolidados []*domainMarcaje.Marcaje
	tipo         domainMarcaje.TipoMarcaje
	err          error
}

func (f *fakeMarcajes) ListarConsolidados(_ context.Context, _ []string, tipo domainMarcaje.TipoMarcaje) ([]*domainMarcaje.Marcaje, error) {
	f.tipo = tipo
	return f.consolidados, f.err
}

// fakeProcesos guarda la marca de agua en memoria.
type fakeProcesos struct {
	marca    *time.Time
	guardada *time.Time
	err      error
}

func (f *fakeProcesos) ObtenerMarca(context.Context, string) (*time.Time, error) {
	return f.marca, f.err
}
func (f *fakeProcesos) GuardarMarca(_ context.Context, _ string, hasta time.Time) error {
	f.guardada = &hasta
	return nil
}

// fakeEstructura solo implementa GetAsignaturaByID.
type fakeEstructura struct {
	repository.EstructuraRepository
	a *academico.Asignatura
}

func (f *fakeEstructura) GetAsignaturaByID(context.Context, string) (*academico.Asignatura, error) {
	return f.a, nil
}

// fakeEspacios solo implementa FindByID.
type fakeEspacios struct {
	repository.EspacioRepository
	e *domainGeo.Espacio
}

func (f *fakeEspacios) FindByID(context.Context, string) (*domainGeo.Espacio, error) { return f.e, nil }

// sesionDePrueba arma una sesión que inicia en `inicio` y cuya ventana de entrada cierra 15 min después.
func sesionDePrueba(id string, inicio time.Time, docentes ...string) *academico.Sesion {
	return academico.ReconstituirSesion(id, "per-1", "asg-1", "mat-1", "g-1", docentes, "esp-1",
		inicio.Format("2006-01-02"), inicio.Format("15:04"), inicio.Add(2*time.Hour).Format("15:04"),
		inicio, inicio.Add(2*time.Hour), inicio.Add(-10*time.Minute), inicio.Add(15*time.Minute),
		nil, nil, academico.EstadoSesionProgramada, 1, nil, nil, nil, "", inicio, inicio)
}
