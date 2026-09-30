package notificaciones

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

func codigoDe(err error) shared.ErrorCode {
	var de *shared.DomainError
	if errors.As(err, &de) {
		return de.Code
	}
	return ""
}

func TestService_RegistrarTokenValida(t *testing.T) {
	tokens := &fakeTokens{}
	s := NewService(tokens, &fakePrefs{}, &fakeCola{})
	ctx := context.Background()
	for _, c := range []struct{ token, plataforma string }{{"", "ANDROID"}, {"abc", "SYMBIAN"}} {
		if err := s.RegistrarToken(ctx, "u1", c.token, c.plataforma, "inst"); codigoDe(err) != shared.ErrValidacion {
			t.Fatalf("%+v: se esperaba VALIDACION, got %v", c, err)
		}
	}
	if err := s.RegistrarToken(ctx, "u1", "  tk  ", " ios ", "inst-1"); err != nil {
		t.Fatal(err)
	}
	g := tokens.guardados[0]
	if g.Token != "tk" || g.Plataforma != "IOS" || g.UsuarioID != "u1" || g.DispositivoID != "inst-1" || g.ActualizadoEn.IsZero() {
		t.Fatalf("token guardado inesperado: %+v", g)
	}
}

// US-NOT-01 AC-04: solo el dueño puede borrar su token.
func TestService_EliminarTokenSoloDueno(t *testing.T) {
	tokens := &fakeTokens{tokens: []repository.TokenPush{{Token: "ajeno", UsuarioID: "u2"}, {Token: "propio", UsuarioID: "u1"}}}
	s := NewService(tokens, &fakePrefs{}, &fakeCola{})
	if err := s.EliminarToken(context.Background(), "u1", "ajeno"); err != nil || len(tokens.eliminados) != 0 {
		t.Fatalf("no debe borrar un token ajeno: err=%v eliminados=%v", err, tokens.eliminados)
	}
	if err := s.EliminarToken(context.Background(), "u1", "propio"); err != nil || len(tokens.eliminados) != 1 {
		t.Fatalf("debe borrar el token propio: err=%v eliminados=%v", err, tokens.eliminados)
	}
	tokens.errListar = errors.New("x")
	if err := s.EliminarToken(context.Background(), "u1", "propio"); err == nil {
		t.Fatal("se esperaba propagar el error")
	}
}

func TestService_PreferenciasPorDefectoYObligatorias(t *testing.T) {
	prefs := &fakePrefs{}
	s := NewService(&fakeTokens{}, prefs, &fakeCola{})
	r, err := s.Preferencias(context.Background(), "u1")
	if err != nil || r.Preferencias != notificacion.PreferenciasPorDefecto() || len(r.Obligatorias) != 1 {
		t.Fatalf("se esperaban las predeterminadas: %+v err=%v", r, err)
	}
	prefs.pref = &notificacion.Preferencias{RecordatorioSesion: true}
	r, _ = s.Preferencias(context.Background(), "u1")
	if !r.CambioHorario || r.CierreVentana {
		t.Fatalf("se esperaban las guardadas con obligatorias: %+v", r.Preferencias)
	}
	prefs.pref, prefs.err = nil, errors.New("x")
	if _, err := s.Preferencias(context.Background(), "u1"); err == nil {
		t.Fatal("se esperaba propagar el error")
	}
}

func TestService_GuardarPreferenciasFuerzaObligatorias(t *testing.T) {
	prefs := &fakePrefs{}
	s := NewService(&fakeTokens{}, prefs, &fakeCola{})
	r, err := s.GuardarPreferencias(context.Background(), "u1", notificacion.Preferencias{})
	if err != nil || !r.CambioHorario || prefs.guardadas == nil || !prefs.guardadas.CambioHorario {
		t.Fatalf("CambioHorario no puede desactivarse: %+v err=%v", r, err)
	}
	prefs.err = errors.New("x")
	if _, err := s.GuardarPreferencias(context.Background(), "u1", notificacion.Preferencias{}); err == nil {
		t.Fatal("se esperaba propagar el error")
	}
}

func TestService_Bandeja(t *testing.T) {
	creada := time.Date(2026, 9, 30, 8, 0, 0, 0, time.UTC)
	cola := &fakeCola{bandeja: []*notificacion.Notificacion{{
		ID: "n1", Tipo: notificacion.TipoCambioHorario, Titulo: "T", Cuerpo: "C",
		Datos: map[string]string{"ruta": "/horario"}, CreadaEn: creada, Leida: true,
	}}}
	s := NewService(&fakeTokens{}, &fakePrefs{}, cola)
	items, err := s.Bandeja(context.Background(), "u1", 500)
	if err != nil || len(items) != 1 || cola.limiteBand != 30 {
		t.Fatalf("items=%v limite=%d err=%v", items, cola.limiteBand, err)
	}
	if it := items[0]; it.ID != "n1" || it.Titulo != "T" || !it.Leida || !it.CreadaEn.Equal(creada) || it.Datos["ruta"] != "/horario" {
		t.Fatalf("item inesperado: %+v", it)
	}
	if _, _ = s.Bandeja(context.Background(), "u1", 50); cola.limiteBand != 50 {
		t.Fatalf("un límite válido se respeta, got %d", cola.limiteBand)
	}
	cola.errBandeja = errors.New("x")
	if _, err := s.Bandeja(context.Background(), "u1", 10); err == nil {
		t.Fatal("se esperaba propagar el error")
	}
}

func TestService_MarcarLeida(t *testing.T) {
	cola := &fakeCola{}
	s := NewService(&fakeTokens{}, &fakePrefs{}, cola)
	if err := s.MarcarLeida(context.Background(), "u1", "n-ajena"); codigoDe(err) != shared.ErrRecursoNoEncontrado {
		t.Fatalf("un aviso ajeno responde 404, got %v", err)
	}
	cola.leidaOK = true
	if err := s.MarcarLeida(context.Background(), "u1", "n1"); err != nil {
		t.Fatal(err)
	}
	cola.errLeida = errors.New("x")
	if err := s.MarcarLeida(context.Background(), "u1", "n1"); err == nil || codigoDe(err) != "" {
		t.Fatalf("se esperaba el error del repositorio tal cual, got %v", err)
	}
}
