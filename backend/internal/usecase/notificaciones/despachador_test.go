package notificaciones

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
)

var ahoraDespacho = time.Date(2026, 9, 30, 15, 0, 0, 0, time.UTC)

// entornoDespacho reúne los dobles de un despachador con un aviso pendiente.
type entornoDespacho struct {
	cola    *fakeCola
	tokens  *fakeTokens
	prefs   *fakePrefs
	disp    *fakeDispositivos
	push    *fakePush
	correo  *fakeCorreo
	usuario *user.Usuario
	franja  notificacion.FranjaSilencio
}

func nuevoEntorno(tipo notificacion.Tipo) *entornoDespacho {
	return &entornoDespacho{
		cola: &fakeCola{pendientes: []*notificacion.Notificacion{{
			ID: "n1", UsuarioID: "u1", Tipo: tipo, Titulo: "Aviso", Estado: notificacion.EstadoPendiente,
		}}},
		tokens:  &fakeTokens{tokens: []repository.TokenPush{{Token: "tk1", UsuarioID: "u1"}}},
		prefs:   &fakePrefs{},
		disp:    &fakeDispositivos{},
		push:    &fakePush{errores: map[string]error{}},
		correo:  &fakeCorreo{},
		usuario: &user.Usuario{ID: "u1", Correo: "docente@siaa.edu.co", Activo: true},
	}
}

func (e *entornoDespacho) ejecutar(t *testing.T) (*notificacion.Notificacion, int) {
	t.Helper()
	d := NewDespachador(e.cola, e.tokens, e.prefs, &fakeUsuarios{u: e.usuario}, e.disp, e.push, e.correo, e.franja)
	n, err := d.EjecutarCiclo(context.Background(), ahoraDespacho)
	if err != nil {
		t.Fatalf("error inesperado: %v", err)
	}
	if len(e.cola.actualizados) != 1 {
		t.Fatalf("se esperaba 1 aviso actualizado, hay %d", len(e.cola.actualizados))
	}
	return e.cola.actualizados[0], n
}

func TestDespachador_PushExitoso(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoRecordatorioSesion)
	n, enviados := e.ejecutar(t)
	if enviados != 1 || n.Estado != notificacion.EstadoEnviada || n.Canal != notificacion.CanalPush {
		t.Fatalf("se esperaba ENVIADA por push, got estado=%s canal=%s enviados=%d", n.Estado, n.Canal, enviados)
	}
	if n.EnviadaEn == nil || !n.EnviadaEn.Equal(ahoraDespacho) {
		t.Fatalf("EnviadaEn debe ser la hora del ciclo")
	}
}

func TestDespachador_VencidaSeDescarta(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoCierreVentana)
	vence := ahoraDespacho.Add(-time.Minute)
	e.cola.pendientes[0].VenceEn = &vence
	n, _ := e.ejecutar(t)
	if n.Estado != notificacion.EstadoDescartada || len(e.push.envios) != 0 {
		t.Fatalf("un aviso vencido se descarta sin enviarse, got %s", n.Estado)
	}
}

func TestDespachador_PreferenciaDesactivadaSeDescarta(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoRecordatorioSesion)
	p := notificacion.PreferenciasPorDefecto()
	p.RecordatorioSesion = false
	e.prefs.pref = &p
	n, _ := e.ejecutar(t)
	if n.Estado != notificacion.EstadoDescartada {
		t.Fatalf("se esperaba DESCARTADA, got %s", n.Estado)
	}
}

// CAMBIO_HORARIO es obligatorio: sale aunque la preferencia guardada diga lo contrario.
func TestDespachador_CambioHorarioObligatorio(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoCambioHorario)
	e.prefs.pref = &notificacion.Preferencias{}
	n, _ := e.ejecutar(t)
	if n.Estado != notificacion.EstadoEnviada {
		t.Fatalf("el cambio de horario es obligatorio, got %s", n.Estado)
	}
}

func TestDespachador_FranjaSilencioAplaza(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoResultadoJustificacion)
	// Franja 14:00-16:00 UTC: a las 15:00 se aplaza hasta las 16:00.
	e.franja = notificacion.FranjaSilencio{Inicio: 14 * 60, Fin: 16 * 60, Zona: time.UTC, Activa: true}
	n, _ := e.ejecutar(t)
	fin := time.Date(2026, 9, 30, 16, 0, 0, 0, time.UTC)
	if n.Estado != notificacion.EstadoPendiente || !n.ProgramadaPara.Equal(fin) || len(e.push.envios) != 0 {
		t.Fatalf("se esperaba aplazar hasta %v, got estado=%s programada=%v", fin, n.Estado, n.ProgramadaPara)
	}
}

func TestDespachador_FranjaSilencioYVencidaAlTerminar(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoCierreVentana)
	e.franja = notificacion.FranjaSilencio{Inicio: 14 * 60, Fin: 16 * 60, Zona: time.UTC, Activa: true}
	vence := ahoraDespacho.Add(30 * time.Minute)
	e.cola.pendientes[0].VenceEn = &vence
	n, _ := e.ejecutar(t)
	if n.Estado != notificacion.EstadoDescartada {
		t.Fatalf("si vence durante la franja se descarta, got %s", n.Estado)
	}
}

// US-NOT-01 AC-04: el token de un dispositivo revocado se purga y no recibe el aviso.
func TestDespachador_DispositivoRevocado(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoRecordatorioSesion)
	revocado := ahoraDespacho.Add(-time.Hour)
	e.tokens.tokens = []repository.TokenPush{
		{Token: "viejo", UsuarioID: "u1", DispositivoID: "inst-viejo"},
		{Token: "nuevo", UsuarioID: "u1", DispositivoID: "inst-nuevo"},
	}
	e.disp.porInstalacion = map[string]*user.Dispositivo{
		"inst-viejo": {RevocadoEn: &revocado},
		"inst-nuevo": {},
	}
	n, _ := e.ejecutar(t)
	if len(e.push.envios) != 1 || e.push.envios[0] != "nuevo" {
		t.Fatalf("solo el dispositivo vigente recibe el aviso, got %v", e.push.envios)
	}
	if len(e.tokens.eliminados) != 1 || e.tokens.eliminados[0] != "viejo" {
		t.Fatalf("se esperaba purgar el token revocado, got %v", e.tokens.eliminados)
	}
	if n.Estado != notificacion.EstadoEnviada {
		t.Fatalf("got %s", n.Estado)
	}
}

// US-NOT-01 AC-03: el token caducado se elimina; sin otro canal queda SIN_CANAL.
func TestDespachador_TokenInvalidoSePurga(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoRecordatorioSesion)
	e.push.errores["tk1"] = notificacion.ErrTokenInvalido
	n, _ := e.ejecutar(t)
	if len(e.tokens.eliminados) != 1 || e.tokens.eliminados[0] != "tk1" {
		t.Fatalf("se esperaba purgar tk1, got %v", e.tokens.eliminados)
	}
	if n.Estado != notificacion.EstadoSinCanal || n.Intentos != 0 {
		t.Fatalf("se esperaba SIN_CANAL sin reintentos, got %s intentos=%d", n.Estado, n.Intentos)
	}
}

func TestDespachador_ErrorTransitorioReintentaConEspera(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoRecordatorioSesion)
	e.push.errores["tk1"] = errors.New("fcm 503")
	e.cola.pendientes[0].Intentos = 2
	n, enviados := e.ejecutar(t)
	if enviados != 0 || n.Estado != notificacion.EstadoPendiente || n.Intentos != 3 {
		t.Fatalf("se esperaba seguir PENDIENTE con 3 intentos, got %s intentos=%d", n.Estado, n.Intentos)
	}
	if want := ahoraDespacho.Add(8 * time.Minute); !n.ProgramadaPara.Equal(want) {
		t.Fatalf("espera exponencial: se esperaba %v, got %v", want, n.ProgramadaPara)
	}
	if n.UltimoError != "fcm 503" {
		t.Fatalf("UltimoError = %q", n.UltimoError)
	}
}

func TestDespachador_ErrorAlListarTokensReintenta(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoRecordatorioSesion)
	e.tokens.errListar = errors.New("mongo caído")
	n, _ := e.ejecutar(t)
	if n.Intentos != 1 || n.Estado != notificacion.EstadoPendiente || n.UltimoError != "mongo caído" {
		t.Fatalf("got estado=%s intentos=%d err=%q", n.Estado, n.Intentos, n.UltimoError)
	}
}

func TestDespachador_AgotaIntentosYUsaCorreoEnCambioHorario(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoCambioHorario)
	e.push.errores["tk1"] = errors.New("timeout")
	e.cola.pendientes[0].Intentos = notificacion.MaxIntentos - 1
	e.cola.pendientes[0].Titulo = "Clase cancelada"
	n, enviados := e.ejecutar(t)
	if enviados != 1 || n.Estado != notificacion.EstadoEnviada || n.Canal != notificacion.CanalCorreo || n.UltimoError != "" {
		t.Fatalf("se esperaba respaldo por correo, got %s canal=%s err=%q", n.Estado, n.Canal, n.UltimoError)
	}
	if len(e.correo.para) != 1 || e.correo.para[0] != "docente@siaa.edu.co" || e.correo.asunto[0] != "SIAA - Clase cancelada" {
		t.Fatalf("correo inesperado: %v %v", e.correo.para, e.correo.asunto)
	}
}

func TestDespachador_AgotaIntentosSinCorreoFalla(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoRecordatorioSesion)
	e.push.errores["tk1"] = errors.New("timeout")
	e.cola.pendientes[0].Intentos = notificacion.MaxIntentos - 1
	n, _ := e.ejecutar(t)
	if n.Estado != notificacion.EstadoFallida || len(e.correo.para) != 0 {
		t.Fatalf("un recordatorio no sale por correo: se esperaba FALLIDA, got %s", n.Estado)
	}
}

func TestDespachador_SinPushNiCorreoQuedaSinCanal(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoCambioHorario)
	d := NewDespachador(e.cola, e.tokens, e.prefs, nil, nil, nil, nil, notificacion.FranjaSilencio{})
	if _, err := d.EjecutarCiclo(context.Background(), ahoraDespacho); err != nil {
		t.Fatal(err)
	}
	if n := e.cola.actualizados[0]; n.Estado != notificacion.EstadoSinCanal {
		t.Fatalf("se esperaba SIN_CANAL, got %s", n.Estado)
	}
}

func TestDespachador_SinTokensUsaCorreoSoloSiUsuarioActivo(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoCambioHorario)
	e.tokens.tokens = nil
	e.usuario.Activo = false
	n, _ := e.ejecutar(t)
	if n.Estado != notificacion.EstadoSinCanal || len(e.correo.para) != 0 {
		t.Fatalf("un usuario inactivo no recibe correo, got %s", n.Estado)
	}
}

func TestDespachador_ErroresDeLaCola(t *testing.T) {
	e := nuevoEntorno(notificacion.TipoRecordatorioSesion)
	e.cola.errPend = errors.New("sin conexión")
	d := NewDespachador(e.cola, e.tokens, e.prefs, nil, nil, e.push, nil, notificacion.FranjaSilencio{})
	if _, err := d.EjecutarCiclo(context.Background(), ahoraDespacho); err == nil {
		t.Fatal("se esperaba el error de Pendientes")
	}
	e.cola.errPend, e.cola.errAct = nil, errors.New("fallo al actualizar")
	if n, err := d.EjecutarCiclo(context.Background(), ahoraDespacho); err == nil || n != 1 {
		t.Fatalf("se esperaba propagar el error de Actualizar con 1 enviado, got n=%d err=%v", n, err)
	}
}
