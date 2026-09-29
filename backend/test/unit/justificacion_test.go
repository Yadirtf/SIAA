package unit

import (
	"errors"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/justificacion"
)

func nuevaJustificacion(t *testing.T) *justificacion.Justificacion {
	t.Helper()
	j, err := justificacion.Nueva("ses-1", "doc-1", justificacion.TipoPermiso, "Permiso por diligencia personal",
		[]justificacion.Adjunto{{ID: "a1"}}, time.Now())
	if err != nil {
		t.Fatalf("crear justificación: %v", err)
	}
	return j
}

func TestJustificacion_Radicacion(t *testing.T) {
	ahora := time.Now()
	casos := []struct {
		nombre string
		tipo   justificacion.Tipo
		desc   string
		adj    []justificacion.Adjunto
		err    error
	}{
		{"tipo fuera del catálogo", "VACACIONES", "Descripción suficiente", []justificacion.Adjunto{{ID: "a"}}, justificacion.ErrTipoInvalido},
		{"descripción corta", justificacion.TipoComision, "corta", []justificacion.Adjunto{{ID: "a"}}, justificacion.ErrDescripcionCorta},
		{"sin soporte", justificacion.TipoCalamidad, "Calamidad doméstica grave", nil, justificacion.ErrSinSoporte},
	}
	for _, c := range casos {
		if _, err := justificacion.Nueva("s", "d", c.tipo, c.desc, c.adj, ahora); !errors.Is(err, c.err) {
			t.Errorf("%s: se esperaba %v, se obtuvo %v", c.nombre, c.err, err)
		}
	}
	j := nuevaJustificacion(t)
	if j.Estado != justificacion.EstadoRadicada || !j.Vigente() || j.Aprobada() || len(j.Historial) != 1 {
		t.Fatalf("estado inicial inválido: %+v", j)
	}
}

func TestJustificacion_Transiciones(t *testing.T) {
	ahora := time.Now()
	j := nuevaJustificacion(t)
	if err := j.Transitar(justificacion.EstadoAprobada, "doc-1", "", ahora); !errors.Is(err, justificacion.ErrRevisorEsSolicitante) {
		t.Fatalf("el solicitante no puede aprobar: %v", err)
	}
	if err := j.Transitar(justificacion.EstadoRechazada, "coord", "no", ahora); !errors.Is(err, justificacion.ErrObservacionesCortas) {
		t.Fatalf("rechazar exige observaciones: %v", err)
	}
	if err := j.Transitar(justificacion.EstadoRadicada, "coord", "", ahora); !errors.Is(err, justificacion.ErrEstadoDestinoInvalido) {
		t.Fatalf("destino inválido: %v", err)
	}
	if err := j.Transitar(justificacion.EstadoEnRevision, "coord", "", ahora); err != nil {
		t.Fatalf("pasar a revisión: %v", err)
	}
	if err := j.Transitar(justificacion.EstadoEnRevision, "coord", "", ahora); !errors.Is(err, justificacion.ErrTransicionInvalida) {
		t.Fatalf("revisión repetida: %v", err)
	}
	if err := j.Transitar(justificacion.EstadoRechazada, "coord", "El soporte no corresponde a la fecha", ahora); err != nil {
		t.Fatalf("rechazar: %v", err)
	}
	if j.Vigente() || j.RevisorID != "coord" || len(j.Historial) != 3 {
		t.Fatalf("estado final inválido: %+v", j)
	}
	if err := j.Transitar(justificacion.EstadoAprobada, "coord", "", ahora); !errors.Is(err, justificacion.ErrTransicionInvalida) {
		t.Fatalf("una decisión final no cambia: %v", err)
	}
}

func TestJustificacion_PlazoDiasHabiles(t *testing.T) {
	viernes := time.Date(2026, 9, 25, 0, 0, 0, 0, time.UTC)
	casos := []struct {
		ahora time.Time
		ok    bool
	}{
		{time.Date(2026, 10, 2, 23, 59, 0, 0, time.UTC), true}, // 5 días hábiles: vence el viernes siguiente
		{time.Date(2026, 10, 3, 0, 0, 1, 0, time.UTC), false},
		{time.Date(2026, 9, 28, 8, 0, 0, 0, time.UTC), true},
	}
	for _, c := range casos {
		if got := justificacion.DentroDelPlazo(viernes, c.ahora, 5); got != c.ok {
			t.Errorf("DentroDelPlazo(%s) = %v, se esperaba %v", c.ahora, got, c.ok)
		}
	}
}
