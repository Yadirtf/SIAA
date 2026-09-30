package notificaciones

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
)

var ahoraProgramador = time.Date(2026, 9, 30, 12, 0, 0, 0, time.UTC)

func nuevoProgramador(agenda *fakeAgenda, marcajes *fakeMarcajes, procesos *fakeProcesos, cola *fakeCola) *Programador {
	return NewProgramador(agenda, marcajes, procesos, NewProductor(cola, nil, nil))
}

// En la primera ejecución no hay marca: la ventana es vacía [ahora, ahora] desplazada.
func TestProgramador_PrimeraEjecucionUsaAhora(t *testing.T) {
	agenda, procesos := &fakeAgenda{}, &fakeProcesos{}
	p := nuevoProgramador(agenda, &fakeMarcajes{}, procesos, &fakeCola{})
	n, err := p.EjecutarCiclo(context.Background(), ahoraProgramador)
	if err != nil || n != 0 {
		t.Fatalf("n=%d err=%v", n, err)
	}
	want := ahoraProgramador.Add(15 * time.Minute)
	if !agenda.ventanaInicio[0].Equal(want) || !agenda.ventanaInicio[1].Equal(want) {
		t.Fatalf("ventana de recordatorios inesperada: %v", agenda.ventanaInicio)
	}
	if procesos.guardada == nil || !procesos.guardada.Equal(ahoraProgramador) {
		t.Fatalf("la marca de agua debe quedar en ahora, got %v", procesos.guardada)
	}
}

func TestProgramador_UsaMarcaAnteriorYAnticipacion(t *testing.T) {
	marca := ahoraProgramador.Add(-time.Minute)
	agenda := &fakeAgenda{}
	p := nuevoProgramador(agenda, &fakeMarcajes{}, &fakeProcesos{marca: &marca}, &fakeCola{}).ConAnticipacion(20, 10)
	if _, err := p.EjecutarCiclo(context.Background(), ahoraProgramador); err != nil {
		t.Fatal(err)
	}
	if !agenda.ventanaInicio[0].Equal(marca.Add(20*time.Minute)) || !agenda.ventanaInicio[1].Equal(ahoraProgramador.Add(20*time.Minute)) {
		t.Fatalf("ventana de recordatorios inesperada: %v", agenda.ventanaInicio)
	}
	if !agenda.ventanaCierre[0].Equal(marca.Add(10*time.Minute)) || !agenda.ventanaCierre[1].Equal(ahoraProgramador.Add(10*time.Minute)) {
		t.Fatalf("ventana de cierre inesperada: %v", agenda.ventanaCierre)
	}
}

// Una marca en el futuro (reloj adelantado) no se respeta: se parte de ahora.
func TestProgramador_MarcaFuturaSeIgnora(t *testing.T) {
	marca := ahoraProgramador.Add(time.Hour)
	agenda := &fakeAgenda{}
	p := nuevoProgramador(agenda, &fakeMarcajes{}, &fakeProcesos{marca: &marca}, &fakeCola{}).ConAnticipacion(0, 0)
	if _, err := p.EjecutarCiclo(context.Background(), ahoraProgramador); err != nil {
		t.Fatal(err)
	}
	if !agenda.ventanaInicio[0].Equal(ahoraProgramador.Add(15 * time.Minute)) {
		t.Fatalf("se esperaba partir de ahora, got %v", agenda.ventanaInicio[0])
	}
}

func TestProgramador_RecordatoriosPorDocente(t *testing.T) {
	s := sesionDePrueba("ses-1", ahoraProgramador.Add(15*time.Minute), "doc-1", "doc-2")
	cola := &fakeCola{}
	p := nuevoProgramador(&fakeAgenda{inician: []*academico.Sesion{s}}, &fakeMarcajes{}, &fakeProcesos{}, cola)
	n, err := p.EjecutarCiclo(context.Background(), ahoraProgramador)
	if err != nil || n != 2 || len(cola.encolados) != 2 {
		t.Fatalf("se esperaban 2 recordatorios, n=%d encolados=%d err=%v", n, len(cola.encolados), err)
	}
	if cola.encolados[1].UsuarioID != "doc-2" || cola.encolados[1].ClaveDedupe != "recordatorio:ses-1:doc-2" {
		t.Fatalf("recordatorio inesperado: %+v", cola.encolados[1])
	}
}

// US-MAR-12 AC-02: quien ya tiene ENTRADA consolidada no recibe el aviso de cierre.
func TestProgramador_CierreOmiteQuienYaMarco(t *testing.T) {
	s := sesionDePrueba("ses-2", ahoraProgramador.Add(-10*time.Minute), "doc-1", "doc-2")
	cola := &fakeCola{}
	marcajes := &fakeMarcajes{consolidados: []*domainMarcaje.Marcaje{{SesionID: "ses-2", UsuarioID: "doc-1"}}}
	procesos := &fakeProcesos{}
	p := nuevoProgramador(&fakeAgenda{cierran: []*academico.Sesion{s}}, marcajes, procesos, cola)
	n, err := p.EjecutarCiclo(context.Background(), ahoraProgramador)
	if err != nil || n != 1 {
		t.Fatalf("se esperaba 1 aviso de cierre, n=%d err=%v", n, err)
	}
	if marcajes.tipo != domainMarcaje.TipoEntrada {
		t.Fatalf("debe consultar marcajes de ENTRADA, got %s", marcajes.tipo)
	}
	if c := cola.encolados[0]; c.UsuarioID != "doc-2" || c.ClaveDedupe != "cierre:ses-2:doc-2" {
		t.Fatalf("aviso inesperado: %+v", c)
	}
	if procesos.guardada == nil {
		t.Fatal("la marca de agua debe guardarse")
	}
}

func TestProgramador_ErroresNoAvanzanLaMarca(t *testing.T) {
	marca := ahoraProgramador.Add(-time.Minute)
	casos := map[string]struct {
		agenda   *fakeAgenda
		marcajes *fakeMarcajes
		procesos *fakeProcesos
	}{
		"obtener marca": {&fakeAgenda{}, &fakeMarcajes{}, &fakeProcesos{err: errors.New("x")}},
		"inician":       {&fakeAgenda{errInician: errors.New("x")}, &fakeMarcajes{}, &fakeProcesos{marca: &marca}},
		"cierran":       {&fakeAgenda{errCierran: errors.New("x")}, &fakeMarcajes{}, &fakeProcesos{}},
		"consolidados": {&fakeAgenda{cierran: []*academico.Sesion{sesionDePrueba("s", ahoraProgramador, "d")}},
			&fakeMarcajes{err: errors.New("x")}, &fakeProcesos{}},
	}
	for nombre, c := range casos {
		t.Run(nombre, func(t *testing.T) {
			p := nuevoProgramador(c.agenda, c.marcajes, c.procesos, &fakeCola{})
			if _, err := p.EjecutarCiclo(context.Background(), ahoraProgramador); err == nil {
				t.Fatal("se esperaba error")
			}
			if c.procesos.guardada != nil {
				t.Fatal("con error no debe avanzar la marca de agua")
			}
		})
	}
}
