package privacidad

import (
	"context"
	"errors"
	"testing"
	"time"

	dompar "github.com/siaa/backend/internal/domain/parametro"
	"github.com/siaa/backend/internal/repository"
)

// fakeRetencion registra el límite pedido y devuelve la cantidad configurada.
type fakeRetencion struct {
	antesDe time.Time
	n       int64
	err     error
}

func (f *fakeRetencion) AnonimizarUbicaciones(_ context.Context, antesDe time.Time) (int64, error) {
	f.antesDe = antesDe
	return f.n, f.err
}

// fakeParametros solo implementa FindByAmbitoAndClave.
type fakeParametros struct {
	repository.ParametroRepository
	p     *dompar.Parametro
	err   error
	clave dompar.Clave
}

func (f *fakeParametros) FindByAmbitoAndClave(_ context.Context, _ dompar.Ambito, _ string, c dompar.Clave) (*dompar.Parametro, error) {
	f.clave = c
	return f.p, f.err
}

func TestRetencion_DiasPorDefectoYTiposDeValor(t *testing.T) {
	casos := []struct {
		nombre string
		params repository.ParametroRepository
		dias   int
	}{
		{"sin repositorio", nil, 365},
		{"sin parámetro", &fakeParametros{}, 365},
		{"error al leer", &fakeParametros{err: errors.New("x")}, 365},
		{"int", &fakeParametros{p: &dompar.Parametro{Valor: 90}}, 90},
		{"int32", &fakeParametros{p: &dompar.Parametro{Valor: int32(120)}}, 120},
		{"int64", &fakeParametros{p: &dompar.Parametro{Valor: int64(180)}}, 180},
		{"float64", &fakeParametros{p: &dompar.Parametro{Valor: float64(730)}}, 730},
		{"tipo desconocido", &fakeParametros{p: &dompar.Parametro{Valor: "30"}}, 365},
	}
	for _, c := range casos {
		t.Run(c.nombre, func(t *testing.T) {
			if d := NewRetencionWorker(&fakeRetencion{}, c.params, nil).DiasRetencion(context.Background()); d != c.dias {
				t.Fatalf("se esperaban %d días, got %d", c.dias, d)
			}
		})
	}
}

func TestRetencion_EjecutarCicloAnonimizaYAudita(t *testing.T) {
	ahora := time.Date(2026, 9, 30, 3, 0, 0, 0, time.UTC)
	ret, aud := &fakeRetencion{n: 7}, &fakeAuditoria{}
	params := &fakeParametros{p: &dompar.Parametro{Valor: int32(30)}}
	n, err := NewRetencionWorker(ret, params, aud).EjecutarCiclo(context.Background(), ahora)
	if err != nil || n != 7 {
		t.Fatalf("n=%d err=%v", n, err)
	}
	if params.clave != dompar.ClaveRetencionCoordenadasDias {
		t.Fatalf("clave consultada inesperada %q", params.clave)
	}
	if want := ahora.AddDate(0, 0, -30); !ret.antesDe.Equal(want) {
		t.Fatalf("límite esperado %v, got %v", want, ret.antesDe)
	}
	if len(aud.entradas) != 1 {
		t.Fatalf("se esperaba 1 entrada de auditoría, hay %d", len(aud.entradas))
	}
	a := aud.entradas[0]
	if a.Accion != "UBICACIONES_ANONIMIZADAS" || a.Entidad != "marcajes" || a.ActorID != "sistema" || !a.CreadoEn.Equal(ahora) {
		t.Fatalf("auditoría inesperada %+v", a)
	}
	v := a.ValorNuevo.(map[string]interface{})
	if v["cantidad"] != int64(7) || v["retencionDias"] != 30 {
		t.Fatalf("valor auditado inesperado %v", v)
	}
}

func TestRetencion_SinCambiosNoAudita(t *testing.T) {
	aud := &fakeAuditoria{}
	if _, err := NewRetencionWorker(&fakeRetencion{}, nil, aud).EjecutarCiclo(context.Background(), time.Now()); err != nil {
		t.Fatal(err)
	}
	if len(aud.entradas) != 0 {
		t.Fatal("sin marcajes anonimizados no se audita")
	}
	if _, err := NewRetencionWorker(&fakeRetencion{n: 3}, nil, nil).EjecutarCiclo(context.Background(), time.Now()); err != nil {
		t.Fatalf("sin bitácora no debe fallar: %v", err)
	}
}

func TestRetencion_ErrorSeEnvuelve(t *testing.T) {
	causa := errors.New("mongo caído")
	aud := &fakeAuditoria{}
	_, err := NewRetencionWorker(&fakeRetencion{n: 2, err: causa}, nil, aud).EjecutarCiclo(context.Background(), time.Now())
	if !errors.Is(err, causa) || err.Error() != "anonimizar ubicaciones: mongo caído" {
		t.Fatalf("error inesperado %v", err)
	}
	if len(aud.entradas) != 0 {
		t.Fatal("con error no se audita")
	}
}
