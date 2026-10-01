package notificaciones

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	domainGeo "github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/notificacion"
)

// 15:00 UTC = 10:00 en Bogotá.
var inicioClase = time.Date(2026, 9, 30, 15, 0, 0, 0, time.UTC)

func productorConNombres(cola *fakeCola) *Productor {
	asig := academico.ReconstituirAsignatura("mat-1", "MAT101", "Cálculo", "prog-1", 3, nil, false, inicioClase, inicioClase)
	return NewProductor(cola, &fakeEstructura{a: asig}, &fakeEspacios{e: &domainGeo.Espacio{Codigo: "A-301"}})
}

func TestProductor_RecordatorioSesion(t *testing.T) {
	cola := &fakeCola{}
	s := sesionDePrueba("ses-1", inicioClase, "doc-1")
	productorConNombres(cola).RecordatorioSesion(context.Background(), s, "doc-1")
	n := cola.encolados[0]
	if n.Tipo != notificacion.TipoRecordatorioSesion || n.ClaveDedupe != "recordatorio:ses-1:doc-1" || n.UsuarioID != "doc-1" {
		t.Fatalf("aviso inesperado: %+v", n)
	}
	if n.Datos["ruta"] != "/marcaje" || n.Datos["sesionId"] != "ses-1" {
		t.Fatalf("datos inesperados: %v", n.Datos)
	}
	if !strings.Contains(n.Cuerpo, "Cálculo (A-301) inicia a las 10:00") {
		t.Fatalf("cuerpo inesperado: %q", n.Cuerpo)
	}
	if n.VenceEn == nil || !n.VenceEn.Equal(s.VentanaEntradaCierra()) {
		t.Fatalf("el recordatorio vence al cerrar la ventana de entrada")
	}
}

func TestProductor_CierreVentanaSinNombres(t *testing.T) {
	cola := &fakeCola{}
	s := sesionDePrueba("ses-2", inicioClase, "doc-1")
	NewProductor(cola, nil, nil).CierreVentana(context.Background(), s, "doc-1")
	n := cola.encolados[0]
	if n.ClaveDedupe != "cierre:ses-2:doc-1" || n.Datos["ruta"] != "/marcaje" || n.Datos["sesionId"] != "ses-2" {
		t.Fatalf("aviso inesperado: %+v", n)
	}
	if !strings.Contains(n.Cuerpo, "tu clase") || !strings.Contains(n.Cuerpo, "10:15") {
		t.Fatalf("cuerpo inesperado: %q", n.Cuerpo)
	}
}

func TestProductor_ResultadoJustificacion(t *testing.T) {
	casos := []struct {
		aprobada       bool
		titulo, sufijo string
	}{
		{true, "Justificación aprobada", "aprobada"},
		{false, "Justificación rechazada", "rechazada"},
	}
	for _, c := range casos {
		cola := &fakeCola{}
		NewProductor(cola, nil, nil).ResultadoJustificacion(context.Background(), "doc-1", "jus-9", "Cálculo", c.aprobada)
		n := cola.encolados[0]
		if n.Titulo != c.titulo || n.ClaveDedupe != "justificacion:jus-9:"+c.sufijo {
			t.Fatalf("título/clave inesperados: %q %q", n.Titulo, n.ClaveDedupe)
		}
		if n.Datos["ruta"] != "/justificaciones" || n.Datos["justificacionId"] != "jus-9" || n.VenceEn != nil {
			t.Fatalf("datos inesperados: %v", n.Datos)
		}
	}
}

func TestProductor_CambioSesionUnoPorDocente(t *testing.T) {
	cola := &fakeCola{}
	s := sesionDePrueba("ses-3", inicioClase, "doc-1", "doc-2")
	productorConNombres(cola).CambioSesion(context.Background(), s, []string{"doc-1", "doc-2"}, "Clase cancelada", "Motivo: paro")
	if len(cola.encolados) != 2 {
		t.Fatalf("se esperaban 2 avisos, hay %d", len(cola.encolados))
	}
	for i, d := range []string{"doc-1", "doc-2"} {
		n := cola.encolados[i]
		if n.UsuarioID != d || n.Tipo != notificacion.TipoCambioHorario || n.Titulo != "Clase cancelada" {
			t.Fatalf("aviso inesperado: %+v", n)
		}
		if !strings.HasPrefix(n.ClaveDedupe, "cambio:ses-3:"+d+":") || n.Datos["ruta"] != "/horario" {
			t.Fatalf("clave/datos inesperados: %q %v", n.ClaveDedupe, n.Datos)
		}
		if n.Cuerpo != "Cálculo (A-301) del 30/09 a las 10:00 a. m. Motivo: paro" {
			t.Fatalf("cuerpo inesperado: %q", n.Cuerpo)
		}
	}
}
