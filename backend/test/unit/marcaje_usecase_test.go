package unit

import (
	"context"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/geo"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
	usecaseMarcaje "github.com/siaa/backend/internal/usecase/marcaje"
)

// Fake in-memory repositories for pure and fast testing
type fakeMarcajeRepo struct {
	mu       sync.Mutex
	items    map[string]*domainMarcaje.Marcaje
	porClave map[string]*domainMarcaje.Marcaje // sesion:usuario:tipo
}

func newFakeMarcajeRepo() *fakeMarcajeRepo {
	return &fakeMarcajeRepo{
		items:    make(map[string]*domainMarcaje.Marcaje),
		porClave: make(map[string]*domainMarcaje.Marcaje),
	}
}

func (r *fakeMarcajeRepo) Crear(ctx context.Context, m *domainMarcaje.Marcaje) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	clave := fmt.Sprintf("%s:%s:%s", m.SesionID, m.UsuarioID, m.Tipo)
	if previo, exists := r.porClave[clave]; exists && !previo.Anulado {
		// Simula el comportamiento del índice único parcial de MongoDB (ADR-07, US-MAR-05 AC-03)
		*m = *previo
		return nil
	}

	if m.ID == "" {
		m.ID = fmt.Sprintf("marc-%d", len(r.items)+1)
	}
	r.items[m.ID] = m
	r.porClave[clave] = m
	return nil
}

func (r *fakeMarcajeRepo) ObtenerPorID(ctx context.Context, id string) (*domainMarcaje.Marcaje, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.items[id], nil
}

func (r *fakeMarcajeRepo) ObtenerPrevio(ctx context.Context, sesionID, usuarioID string, tipo domainMarcaje.TipoMarcaje) (*domainMarcaje.Marcaje, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	clave := fmt.Sprintf("%s:%s:%s", sesionID, usuarioID, tipo)
	if m, exists := r.porClave[clave]; exists && !m.Anulado {
		return m, nil
	}
	return nil, nil
}

func (r *fakeMarcajeRepo) ListarPorUsuario(ctx context.Context, usuarioID string, mes string, skip, limit int64) ([]*domainMarcaje.Marcaje, int64, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	var res []*domainMarcaje.Marcaje
	for _, m := range r.items {
		if m.UsuarioID == usuarioID || m.DocenteID == usuarioID {
			res = append(res, m)
		}
	}
	return res, int64(len(res)), nil
}

func (r *fakeMarcajeRepo) ListarConFiltros(ctx context.Context, f repository.FiltrosMarcaje, skip, limit int64) ([]*domainMarcaje.Marcaje, int64, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	var res []*domainMarcaje.Marcaje
	for _, m := range r.items {
		if f.SesionID != "" && m.SesionID != f.SesionID {
			continue
		}
		res = append(res, m)
	}
	return res, int64(len(res)), nil
}

func (r *fakeMarcajeRepo) ActualizarAjuste(ctx context.Context, id string, nuevoResultado domainMarcaje.ResultadoMarcaje, anulado bool, motivo string, ajustadorID string, ajustadoEn time.Time) (*domainMarcaje.Marcaje, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	m, exists := r.items[id]
	if !exists {
		return nil, fmt.Errorf("no encontrado")
	}
	m.Anulado = anulado
	m.MotivoAjuste = motivo
	m.AjustadoPor = ajustadorID
	m.AjustadoEn = &ajustadoEn
	if nuevoResultado != "" {
		m.Resultado = nuevoResultado
	}
	return m, nil
}

func (r *fakeMarcajeRepo) ObtenerSesionesExpiradasSinMarcaje(ctx context.Context, ahora time.Time) ([]*academico.Sesion, error) {
	return nil, nil
}

func (r *fakeMarcajeRepo) ObtenerUltimoMarcajeUsuario(ctx context.Context, usuarioID string) (*domainMarcaje.Marcaje, error) {
	return nil, nil
}

func (r *fakeMarcajeRepo) RevertirAusenciaPorOffline(ctx context.Context, sesionID, usuarioID string, nuevoMarcaje *domainMarcaje.Marcaje) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	for _, m := range r.items {
		if m.SesionID == sesionID && m.UsuarioID == usuarioID && m.Resultado == domainMarcaje.ResultadoAusente {
			m.Anulado = true
			m.MotivoAjuste = "Revertido por marcaje offline"
		}
	}
	r.items[nuevoMarcaje.ID] = nuevoMarcaje
	return nil
}

// Fake SesionRepo
type fakeSesionRepo struct {
	sesiones map[string]*academico.Sesion
}

func (r *fakeSesionRepo) Create(ctx context.Context, s *academico.Sesion) error { return nil }
func (r *fakeSesionRepo) CreateBatch(ctx context.Context, sesiones []*academico.Sesion) (int, error) {
	return len(sesiones), nil
}
func (r *fakeSesionRepo) FindByID(ctx context.Context, id string) (*academico.Sesion, error) {
	return r.sesiones[id], nil
}
func (r *fakeSesionRepo) FindByAsignacionFechaHora(ctx context.Context, asignacionID string, fecha string, horaInicio string) (*academico.Sesion, error) {
	return nil, nil
}
func (r *fakeSesionRepo) ListByPeriodo(ctx context.Context, periodoID string) ([]*academico.Sesion, error) {
	return nil, nil
}
func (r *fakeSesionRepo) ListByDocenteYFecha(ctx context.Context, docenteID string, fecha string) ([]*academico.Sesion, error) {
	var list []*academico.Sesion
	for _, s := range r.sesiones {
		if s.TieneDocente(docenteID) && s.Fecha() == fecha {
			list = append(list, s)
		}
	}
	return list, nil
}
func (r *fakeSesionRepo) List(ctx context.Context, filter repository.SesionFilter) ([]*academico.Sesion, error) {
	return nil, nil
}
func (r *fakeSesionRepo) Update(ctx context.Context, s *academico.Sesion) error { return nil }
func (r *fakeSesionRepo) CountSesionesFuturasPorEspacio(ctx context.Context, espacioID string, desde time.Time) (int64, error) {
	return 0, nil
}

// Fake EspacioRepo
type fakeEspacioRepo struct{}

func (f *fakeEspacioRepo) Create(ctx context.Context, e *geo.Espacio) error { return nil }
func (f *fakeEspacioRepo) FindByID(ctx context.Context, id string) (*geo.Espacio, error) {
	return nil, nil
}
func (f *fakeEspacioRepo) FindByCodigo(ctx context.Context, codigo string) (*geo.Espacio, error) {
	return nil, nil
}
func (f *fakeEspacioRepo) List(ctx context.Context, filter repository.EspacioFilter) ([]*geo.Espacio, error) {
	return nil, nil
}
func (f *fakeEspacioRepo) Update(ctx context.Context, e *geo.Espacio) error { return nil }
func (f *fakeEspacioRepo) SoftDelete(ctx context.Context, id string) error  { return nil }
func (f *fakeEspacioRepo) BuscarIntersecciones(ctx context.Context, espacioID string, bloqueID *string, piso *int, geom geo.GeoPolygon) ([]*geo.Espacio, error) {
	return nil, nil
}

// Fake DispositivoRepo
type fakeDispositivoRepo struct{}

func (f *fakeDispositivoRepo) FindByID(ctx context.Context, id string) (*user.Dispositivo, error) {
	return nil, nil
}
func (f *fakeDispositivoRepo) FindByInstalacion(ctx context.Context, usuarioID, instalacionID string) (*user.Dispositivo, error) {
	return nil, nil
}
func (f *fakeDispositivoRepo) Create(ctx context.Context, d *user.Dispositivo) error { return nil }
func (f *fakeDispositivoRepo) FindByUsuario(ctx context.Context, usuarioID string) ([]*user.Dispositivo, error) {
	return []*user.Dispositivo{{ID: "disp-1", Confiable: true, InstalacionID: "disp-1"}}, nil
}
func (f *fakeDispositivoRepo) FindRecentByInstalacion(ctx context.Context, instalacionID string, desde time.Time) ([]*user.Dispositivo, error) {
	return nil, nil
}
func (f *fakeDispositivoRepo) Update(ctx context.Context, d *user.Dispositivo) error { return nil }

// Fake AuditoriaRepo
type fakeAuditoriaRepo struct {
	entries []*repository.AuditEntry
}

func (f *fakeAuditoriaRepo) Create(ctx context.Context, e *repository.AuditEntry) error {
	f.entries = append(f.entries, e)
	return nil
}

func TestAjustarMarcaje_MotivoObligatorio(t *testing.T) {
	mRepo := newFakeMarcajeRepo()
	audRepo := &fakeAuditoriaRepo{}
	uc := usecaseMarcaje.NewAjustarMarcajeUseCase(mRepo, &fakeSesionRepo{}, audRepo)

	ctx := context.Background()

	// Crear marcaje previo
	mRepo.items["m-1"] = &domainMarcaje.Marcaje{
		ID:        "m-1",
		SesionID:  "ses-1",
		UsuarioID: "doc-1",
		Resultado: domainMarcaje.ResultadoRechazadoFueraDeArea,
	}

	t.Run("Motivo menor a 20 caracteres es rechazado (US-MAR-09 AC-01)", func(t *testing.T) {
		req := usecaseMarcaje.SolicitudAjuste{
			MarcajeID: "m-1",
			Anulado:   true,
			Motivo:    "Muy corto", // < 20 caracteres
		}
		_, err := uc.Ajustar(ctx, req, "admin-1")
		if err != domainMarcaje.ErrMotivoInsuficiente {
			t.Errorf("se esperaba ErrMotivoInsuficiente, obtuvo: %v", err)
		}
	})

	t.Run("Motivo de al menos 20 caracteres aplica ajuste y genera auditoria (AC-01, AC-02, AC-06)", func(t *testing.T) {
		req := usecaseMarcaje.SolicitudAjuste{
			MarcajeID:      "m-1",
			Anulado:        false,
			NuevoResultado: domainMarcaje.ResultadoPresente,
			Motivo:         "Falla comprobada de antena GPS en el bloque norte institucional",
		}
		act, err := uc.Ajustar(ctx, req, "admin-1")
		if err != nil {
			t.Fatalf("error inesperado aplicando ajuste: %v", err)
		}
		if act.Resultado != domainMarcaje.ResultadoPresente {
			t.Errorf("esperado nuevo resultado PRESENTE, obtuvo: %s", act.Resultado)
		}
		if act.AjustadoPor != "admin-1" {
			t.Errorf("esperado ajustadoPor admin-1, obtuvo: %s", act.AjustadoPor)
		}
		if len(audRepo.entries) == 0 {
			t.Errorf("se esperaba registro en auditoria")
		}
	})
}

func TestHistorial_Privacidad(t *testing.T) {
	mRepo := newFakeMarcajeRepo()
	uc := usecaseMarcaje.NewHistorialUseCase(mRepo)
	ctx := context.Background()

	t.Run("Usuario consulta su propio historial — permitido", func(t *testing.T) {
		resp, err := uc.ConsultarHistorialPropio(ctx, "user-1", "user-1", "", 1, 20)
		if err != nil {
			t.Fatalf("error consultando historial propio: %v", err)
		}
		if resp == nil {
			t.Fatalf("respuesta nula")
		}
	})

	t.Run("Usuario intenta consultar historial de otro — Prohibido 403 (US-MAR-08 AC-04)", func(t *testing.T) {
		_, err := uc.ConsultarHistorialPropio(ctx, "user-1", "user-2", "", 1, 20)
		if err != usecaseMarcaje.ErrAccesoHistorialAjeno {
			t.Errorf("esperado ErrAccesoHistorialAjeno, obtuvo: %v", err)
		}
	})
}
