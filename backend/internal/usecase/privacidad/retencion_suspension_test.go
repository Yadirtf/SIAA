package privacidad

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/notificacion"
	domain "github.com/siaa/backend/internal/domain/privacidad"
	"github.com/siaa/backend/internal/repository"
)

// fakeInvestigaciones devuelve las investigaciones activas configuradas.
type fakeInvestigaciones struct {
	repository.InvestigacionRepository
	activas []*domain.Investigacion
	err     error
}

func (f *fakeInvestigaciones) Activas(context.Context) ([]*domain.Investigacion, error) {
	return f.activas, f.err
}

// fakeAvisos deduplica por clave como la cola real.
type fakeAvisos struct {
	repository.NotificacionRepository
	claves map[string]*notificacion.Notificacion
}

func (f *fakeAvisos) Encolar(_ context.Context, n *notificacion.Notificacion) (bool, error) {
	if f.claves == nil {
		f.claves = map[string]*notificacion.Notificacion{}
	}
	if _, ok := f.claves[n.ClaveDedupe]; ok {
		return false, nil
	}
	f.claves[n.ClaveDedupe] = n
	return true, nil
}

func TestRetencion_InvestigacionSuspendeAuditaYAvisa(t *testing.T) {
	ahora := time.Date(2026, 9, 30, 3, 0, 0, 0, time.UTC)
	inv := &domain.Investigacion{ID: "inv-1", Alcance: domain.AlcanceUsuario, ObjetivoID: "doc-1", CreadaPor: "admin-1"}
	ret, aud, avisos := &fakeRetencion{n: 4, retenidos: 2}, &fakeAuditoria{}, &fakeAvisos{}
	w := NewRetencionWorker(ret, nil, aud).WithInvestigaciones(&fakeInvestigaciones{activas: []*domain.Investigacion{inv}}, avisos)

	if _, err := w.EjecutarCiclo(context.Background(), ahora); err != nil {
		t.Fatal(err)
	}
	if len(ret.excluidos.UsuarioIDs) != 1 || ret.excluidos.UsuarioIDs[0] != "doc-1" {
		t.Fatalf("la anonimización debe excluir al usuario investigado: %+v", ret.excluidos)
	}
	var suspendida *repository.AuditEntry
	for _, e := range aud.entradas {
		if e.Accion == AccionRetencionSuspendida {
			suspendida = e
		}
	}
	if suspendida == nil || suspendida.EntidadID != "inv-1" || suspendida.ValorNuevo.(map[string]interface{})["registrosRetenidos"] != int64(2) {
		t.Fatalf("la suspensión debe auditarse con el volumen retenido: %+v", aud.entradas)
	}
	if len(avisos.claves) != 1 {
		t.Fatalf("se debe avisar a quien marcó la investigación: %d", len(avisos.claves))
	}
	for _, n := range avisos.claves {
		if n.UsuarioID != "admin-1" || n.Tipo != domain.TipoAvisoRetencionSuspendida {
			t.Fatalf("aviso inesperado %+v", n)
		}
	}

	// Mismo día: ni aviso ni entrada repetidos.
	antes := len(aud.entradas)
	if _, err := w.EjecutarCiclo(context.Background(), ahora.Add(time.Hour)); err != nil {
		t.Fatal(err)
	}
	if len(aud.entradas) != antes+1 { // solo UBICACIONES_ANONIMIZADAS
		t.Fatalf("la suspensión no debe auditarse dos veces el mismo día: %d → %d", antes, len(aud.entradas))
	}
}

func TestRetencion_SinLeerInvestigacionesNoAnonimiza(t *testing.T) {
	ret := &fakeRetencion{n: 5}
	w := NewRetencionWorker(ret, nil, nil).WithInvestigaciones(&fakeInvestigaciones{err: errors.New("caído")}, nil)
	if n, err := w.EjecutarCiclo(context.Background(), time.Now()); err == nil || n != 0 {
		t.Fatalf("sin saber qué está bajo investigación no se anonimiza: n=%d err=%v", n, err)
	}
	if !ret.antesDe.IsZero() {
		t.Fatal("no debió llamarse a la anonimización")
	}
}
