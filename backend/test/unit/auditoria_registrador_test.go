// US-AUD-01 AC-02: el registrador completa IP, agente de usuario, sesión y rol activo desde la
// petición sin pisar lo que el caso de uso ya trae, y no deja pasar en silencio los fallos.
package unit_test

import (
	"bytes"
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/siaa/backend/internal/platform/auditctx"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/repository"
	usecaseAud "github.com/siaa/backend/internal/usecase/auditoria"
)

// bitacoraEnMemoria guarda las entradas o devuelve el error configurado.
type bitacoraEnMemoria struct {
	entradas []*repository.AuditEntry
	err      error
}

func (b *bitacoraEnMemoria) Create(_ context.Context, e *repository.AuditEntry) error {
	if b.err != nil {
		return b.err
	}
	b.entradas = append(b.entradas, e)
	return nil
}

func TestRegistrador_CompletaOrigenDesdeLaPeticion(t *testing.T) {
	md := &auditctx.Metadatos{IP: "181.50.10.20", AgenteUsuario: "SIAA/1.0", CorrelationID: "corr-1"}
	md.FijarSesion("u-1", "COORDINADOR")
	ctx := auditctx.Con(context.Background(), md)
	destino := &bitacoraEnMemoria{}
	reg := usecaseAud.NewRegistrador(destino, applog.New(applog.LevelError, &bytes.Buffer{}))

	if err := reg.Create(ctx, &repository.AuditEntry{Accion: "X"}); err != nil {
		t.Fatal(err)
	}
	if err := reg.Create(ctx, &repository.AuditEntry{Accion: "Y", ActorID: "u-2", RolActivo: "DOCENTE"}); err != nil {
		t.Fatal(err)
	}
	a, b := destino.entradas[0], destino.entradas[1]
	if a.IPOrigen != "181.50.10.20" || a.AgenteUsuario != "SIAA/1.0" || a.CorrelationID != "corr-1" ||
		a.ActorID != "u-1" || a.RolActivo != "COORDINADOR" || a.CreadoEn.IsZero() {
		t.Fatalf("faltan datos de origen: %+v", a)
	}
	if b.ActorID != "u-2" || b.RolActivo != "DOCENTE" || b.IPOrigen != "181.50.10.20" {
		t.Fatalf("no debe pisar actor ni rol explícitos: %+v", b)
	}

	// Fuera de una petición: el sistema firma como SISTEMA y un anónimo como SIN_SESION.
	_ = reg.Create(context.Background(), &repository.AuditEntry{Accion: "Z", ActorID: "sistema"})
	_ = reg.Create(auditctx.Con(context.Background(), &auditctx.Metadatos{IP: "1.1.1.1"}), &repository.AuditEntry{Accion: "W"})
	if destino.entradas[2].RolActivo != auditctx.RolSistema || destino.entradas[3].RolActivo != auditctx.RolSinSesion {
		t.Fatalf("rol por defecto inesperado: %q, %q", destino.entradas[2].RolActivo, destino.entradas[3].RolActivo)
	}
}

func TestRegistrador_RegistraFallosEnElLog(t *testing.T) {
	var salida bytes.Buffer
	reg := usecaseAud.NewRegistrador(&bitacoraEnMemoria{err: errors.New("mongo caído")}, applog.New(applog.LevelError, &salida))
	err := reg.Create(context.Background(), &repository.AuditEntry{Accion: "MARCAJE_CREADO", Entidad: "marcajes"})
	if err == nil {
		t.Fatal("el error debe propagarse a quien pueda revertir")
	}
	if !strings.Contains(salida.String(), "MARCAJE_CREADO") || !strings.Contains(salida.String(), "mongo caído") {
		t.Fatalf("el fallo debe quedar en el log: %q", salida.String())
	}
}
