package privacidad

import (
	"context"
	"errors"
	"testing"
	"time"

	domain "github.com/siaa/backend/internal/domain/privacidad"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// fakeConsentimientos guarda las decisiones en memoria.
type fakeConsentimientos struct {
	ultimo      *domain.Consentimiento
	registrados []*domain.Consentimiento
	errUltimo   error
	errReg      error
}

func (f *fakeConsentimientos) Registrar(_ context.Context, c *domain.Consentimiento) error {
	if f.errReg != nil {
		return f.errReg
	}
	c.ID = "c-1"
	f.registrados = append(f.registrados, c)
	return nil
}
func (f *fakeConsentimientos) Ultimo(context.Context, string) (*domain.Consentimiento, error) {
	return f.ultimo, f.errUltimo
}

// fakeAuditoria registra las entradas de la bitácora.
type fakeAuditoria struct{ entradas []*repository.AuditEntry }

func (f *fakeAuditoria) Create(_ context.Context, e *repository.AuditEntry) error {
	f.entradas = append(f.entradas, e)
	return nil
}

var fijo = time.Date(2026, 9, 30, 10, 0, 0, 0, time.UTC)

func nuevoServicio(repo *fakeConsentimientos, aud *fakeAuditoria) *Service {
	s := NewService(domain.Politica{Version: "2.0", Institucion: "SIAA"}, repo, aud)
	s.ahora = func() time.Time { return fijo }
	return s
}

func TestService_PoliticaVigente(t *testing.T) {
	if v := nuevoServicio(&fakeConsentimientos{}, nil).Politica().Version; v != "2.0" {
		t.Fatalf("versión inesperada %q", v)
	}
}

func TestService_EstadoYPuedeMarcar(t *testing.T) {
	casos := []struct {
		nombre string
		ultimo *domain.Consentimiento
		puede  bool
	}{
		{"sin decisión", nil, false},
		{"aceptó la vigente", &domain.Consentimiento{Version: "2.0", Decision: domain.DecisionAceptado}, true},
		{"aceptó una versión vieja", &domain.Consentimiento{Version: "1.0", Decision: domain.DecisionAceptado}, false},
		{"rechazó la vigente", &domain.Consentimiento{Version: "2.0", Decision: domain.DecisionRechazado}, false},
	}
	for _, c := range casos {
		t.Run(c.nombre, func(t *testing.T) {
			s := nuevoServicio(&fakeConsentimientos{ultimo: c.ultimo}, nil)
			e, err := s.Estado(context.Background(), "u1")
			if err != nil || e.VersionVigente != "2.0" || e.RequiereAceptacion == c.puede {
				t.Fatalf("estado inesperado %+v err=%v", e, err)
			}
			puede, err := s.PuedeMarcar(context.Background(), "u1")
			if err != nil || puede != c.puede {
				t.Fatalf("PuedeMarcar=%v, se esperaba %v", puede, c.puede)
			}
		})
	}
}

func TestService_EstadoPropagaError(t *testing.T) {
	s := nuevoServicio(&fakeConsentimientos{errUltimo: errors.New("x")}, nil)
	if _, err := s.Estado(context.Background(), "u1"); err == nil {
		t.Fatal("se esperaba error en Estado")
	}
	if puede, err := s.PuedeMarcar(context.Background(), "u1"); err == nil || puede {
		t.Fatal("con error no se permite marcar")
	}
}

// Una app con el texto viejo debe recargar la política antes de decidir.
func TestService_DecidirVersionDistintaEsConflicto(t *testing.T) {
	repo := &fakeConsentimientos{}
	_, err := nuevoServicio(repo, &fakeAuditoria{}).Decidir(context.Background(), SolicitudDecision{UsuarioID: "u1", Version: "1.0", Acepta: true})
	var de *shared.DomainError
	if !errors.As(err, &de) || de.Code != shared.ErrConflictoUnicidad {
		t.Fatalf("se esperaba conflicto, got %v", err)
	}
	if len(repo.registrados) != 0 {
		t.Fatal("no debe registrar la decisión")
	}
}

func TestService_DecidirRegistraYAudita(t *testing.T) {
	casos := []struct {
		acepta bool
		accion string
		puede  bool
	}{
		{true, "CONSENTIMIENTO_ACEPTADO", true},
		{false, "CONSENTIMIENTO_RECHAZADO", false},
	}
	for _, c := range casos {
		t.Run(c.accion, func(t *testing.T) {
			repo, aud := &fakeConsentimientos{}, &fakeAuditoria{}
			req := SolicitudDecision{UsuarioID: "u1", Version: "2.0", Acepta: c.acepta, DispositivoID: "inst-1", IPOrigen: "10.0.0.1"}
			e, err := nuevoServicio(repo, aud).Decidir(context.Background(), req)
			if err != nil || e.PermiteMarcar() != c.puede || e.DecididoEn == nil || !e.DecididoEn.Equal(fijo) {
				t.Fatalf("estado inesperado %+v err=%v", e, err)
			}
			r := repo.registrados[0]
			if r.UsuarioID != "u1" || r.Version != "2.0" || r.DispositivoID != "inst-1" || r.IPOrigen != "10.0.0.1" {
				t.Fatalf("consentimiento inesperado %+v", r)
			}
			a := aud.entradas[0]
			if a.Accion != c.accion || a.Entidad != "consentimientos" || a.EntidadID != "c-1" || a.ActorID != "u1" || a.IPOrigen != "10.0.0.1" {
				t.Fatalf("auditoría inesperada %+v", a)
			}
		})
	}
}

func TestService_DecidirSinAuditoriaYErrorAlRegistrar(t *testing.T) {
	req := SolicitudDecision{UsuarioID: "u1", Version: "2.0", Acepta: true}
	if _, err := NewService(domain.Politica{Version: "2.0"}, &fakeConsentimientos{}, nil).Decidir(context.Background(), req); err != nil {
		t.Fatalf("sin bitácora también se registra: %v", err)
	}
	aud := &fakeAuditoria{}
	if _, err := nuevoServicio(&fakeConsentimientos{errReg: errors.New("x")}, aud).Decidir(context.Background(), req); err == nil {
		t.Fatal("se esperaba propagar el error")
	}
	if len(aud.entradas) != 0 {
		t.Fatal("si no se registró no se audita")
	}
}
