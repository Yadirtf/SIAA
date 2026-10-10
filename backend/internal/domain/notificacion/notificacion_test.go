package notificacion

import (
	"testing"
	"time"
)

func TestFranjaSilencio(t *testing.T) {
	bogota := time.FixedZone("COT", -5*3600)
	f, err := NuevaFranjaSilencio("22:00", "06:00", bogota)
	if err != nil || !f.Activa {
		t.Fatalf("franja: %+v %v", f, err)
	}
	noche := time.Date(2026, 9, 30, 23, 30, 0, 0, bogota)
	madrugada := time.Date(2026, 10, 1, 5, 59, 0, 0, bogota)
	dia := time.Date(2026, 10, 1, 6, 0, 0, 0, bogota)
	if !f.Contiene(noche) || !f.Contiene(madrugada) || f.Contiene(dia) {
		t.Fatal("la franja nocturna debe cruzar la medianoche")
	}
	if fin := f.FinDesde(noche); !fin.Equal(time.Date(2026, 10, 1, 6, 0, 0, 0, bogota)) {
		t.Fatalf("fin de la franja: %v", fin)
	}
	if fin := f.FinDesde(madrugada); !fin.Equal(dia) {
		t.Fatalf("fin de la franja en la madrugada: %v", fin)
	}
	diurna, _ := NuevaFranjaSilencio("12:00", "14:00", bogota)
	if !diurna.Contiene(time.Date(2026, 10, 1, 13, 0, 0, 0, bogota)) || diurna.Contiene(noche) {
		t.Fatal("franja dentro del mismo día")
	}
	sin, _ := NuevaFranjaSilencio("", "", bogota)
	if sin.Contiene(noche) {
		t.Fatal("sin franja nunca hay silencio")
	}
	if _, err := NuevaFranjaSilencio("25:00", "06:00", bogota); err == nil {
		t.Fatal("una hora inválida debe rechazarse")
	}
}

func TestPreferenciasYCatalogo(t *testing.T) {
	p := Preferencias{}
	p.AplicarObligatorias()
	if !p.Permite(TipoCambioHorario) || p.Permite(TipoRecordatorioSesion) || p.Permite(TipoCierreVentana) || p.Permite(TipoResultadoJustificacion) {
		t.Fatalf("preferencias: %+v", p)
	}
	if !PreferenciasPorDefecto().Permite(TipoCierreVentana) {
		t.Fatal("por defecto todo está activo")
	}
	if RutaDe(TipoCierreVentana) != "/marcaje" || RutaDe(TipoResultadoJustificacion) != "/justificaciones" || RutaDe(TipoCambioHorario) != "/horario" {
		t.Fatal("rutas de navegación")
	}
	if !PermiteCorreo(TipoCambioHorario) || PermiteCorreo(TipoCierreVentana) {
		t.Fatal("solo los cambios de horario salen por correo")
	}
	vence := time.Now()
	n := &Notificacion{VenceEn: &vence}
	if !n.Vencida(vence) || (&Notificacion{}).Vencida(vence) {
		t.Fatal("vencimiento")
	}
}

func TestAvisosAdministrativos(t *testing.T) {
	for tipo, ruta := range map[Tipo]string{
		TipoRecordatorioRevision: "/justificaciones/revision",
		TipoVencimientoRol:       "/usuarios",
		TipoSolicitudDerechos:    "/privacidad/derechos",
	} {
		if RutaDe(tipo) != ruta {
			t.Fatalf("ruta de %s: %s", tipo, RutaDe(tipo))
		}
		if !PermiteCorreo(tipo) {
			t.Fatalf("%s debe salir por correo si no hay push", tipo)
		}
		if !PreferenciasPorDefecto().Permite(tipo) || !(Preferencias{}).Permite(tipo) {
			t.Fatalf("%s es institucional: no se puede desactivar", tipo)
		}
	}
}
