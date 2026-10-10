package integration

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/bson"
)

// enviarArchivo sube un archivo como multipart (campo "file") y devuelve estado y cuerpo crudo.
func (e *entorno) enviarArchivo(ruta, nombre, contenido, token string) (int, []byte) {
	e.t.Helper()
	var buf bytes.Buffer
	w := multipart.NewWriter(&buf)
	parte, _ := w.CreateFormFile("file", nombre)
	_, _ = parte.Write([]byte(contenido))
	_ = w.Close()
	req := httptest.NewRequest(http.MethodPost, "/api/v1"+ruta, &buf)
	req.Header.Set("Content-Type", w.FormDataContentType())
	req.Header.Set("Authorization", "Bearer "+token)
	rec := httptest.NewRecorder()
	e.app.Router.ServeHTTP(rec, req)
	if rec.Code >= http.StatusInternalServerError {
		e.t.Fatalf("%s: error interno %d: %s", ruta, rec.Code, rec.Body.String())
	}
	return rec.Code, rec.Body.Bytes()
}

// US-ACA-07: la carga resuelve códigos contra la base, reporta todo antes de aplicar y es atómica.
func TestImportacion_CargaMasivaAcademica(t *testing.T) {
	e := nuevoEntorno(t)
	s := construirEscenario(e)
	a := s.admin
	dia := (int(time.Now().In(bogota).Weekday())+6)%7 + 1
	otroDia := dia%7 + 1
	fila := func(grupo, docente, aula string) string {
		return fmt.Sprintf("2026-2,SIS,MAT1,%s,%s,%s,%d,6:00,07:00,PRESENCIAL\n", grupo, docente, aula, otroDia)
	}
	encabezado := "periodo,programa,asignatura,grupo,docente,aula,dia,horaInicio,horaFin,modalidad\n"
	sucio := encabezado + fila("10", correoDocente, "A-302") + fila("11", "999999", "A-302") +
		fila("12", correoDocente, "Z-999") + "\n" + fila("13", correoDocente, "A-302")

	// AC-01/AC-04/AC-05: informe por fila, sin persistir, con la entidad faltante y la colisión.
	estado, cuerpo := e.enviarArchivo("/academico/importar/preview", "horarios.csv", sucio, a)
	var prev struct {
		TotalFilas, FilasValidas, FilasConError int
		SuperaUmbral                            bool
		Filas                                   []struct {
			NumeroFila   int
			Errores      []string
			Advertencias []string
		}
	}
	_ = json.Unmarshal(cuerpo, &prev)
	if estado != http.StatusOK || prev.TotalFilas != 4 || prev.FilasValidas != 1 || !prev.SuperaUmbral {
		t.Fatalf("preview inesperado %d: %s", estado, cuerpo)
	}
	esperados := map[int]string{3: "El docente '999999' no existe", 4: "El aula 'Z-999' no existe", 6: "Choque de aula con la fila 2"}
	for _, f := range prev.Filas {
		if want, ok := esperados[f.NumeroFila]; ok && !strings.Contains(strings.Join(f.Errores, "|"), want) {
			t.Errorf("fila %d: se esperaba %q en %v", f.NumeroFila, want, f.Errores)
		}
		if f.NumeroFila == 2 && !strings.Contains(strings.Join(f.Advertencias, "|"), "Se creará el grupo '10'") {
			t.Errorf("la fila válida debe advertir el grupo nuevo: %v", f.Advertencias)
		}
	}

	// AC-02: el mismo archivo con la columna de diagnóstico.
	estado, diag := e.enviarArchivo("/academico/importar/diagnostico", "horarios.csv", sucio, a)
	if estado != http.StatusOK || !strings.Contains(string(diag), ",diagnostico") || !strings.Contains(string(diag), "ERROR: El docente '999999' no existe") {
		t.Fatalf("diagnóstico inesperado %d: %s", estado, diag)
	}

	// AC-03: sobre el umbral no se aplica nada.
	listar := func() []map[string]interface{} {
		_, d := e.llamar(http.MethodGet, "/asignaciones?periodoId="+s.periodo, nil, a)
		return elementos(d)
	}
	antes := len(listar())
	if estado, cuerpo := e.enviarArchivo("/academico/importar", "horarios.csv", sucio, a); estado != http.StatusUnprocessableEntity {
		t.Fatalf("carga sobre el umbral: estado %d: %s", estado, cuerpo)
	}
	if n := len(listar()); n != antes {
		t.Fatalf("no debía aplicarse nada: %d asignaciones, antes %d", n, antes)
	}

	// Carga limpia: guarda IDs reales, crea el grupo y queda auditada con el archivo (AC-06).
	limpio := encabezado + fila("10", correoDocente, "A-302")
	estado, cuerpo = e.enviarArchivo("/academico/importar", "horarios.csv", limpio, a)
	if estado != http.StatusCreated || !strings.Contains(string(cuerpo), `"asignacionesCreadas":1`) {
		t.Fatalf("carga limpia: estado %d: %s", estado, cuerpo)
	}
	var nueva map[string]interface{}
	for _, asig := range listar() {
		if texto(asig["id"]) != s.asignacion {
			nueva = asig
		}
	}
	if nueva == nil || texto(nueva["asignaturaId"]) != s.asignatura || texto(nueva["espacioId"]) != s.espacio2 || texto(nueva["facultadId"]) != s.facultad {
		t.Fatalf("la asignación importada debe referenciar IDs reales: %v", nueva)
	}
	if n, _ := e.cliente.DB().Collection("cargas_masivas").CountDocuments(context.Background(), bson.M{}); n != 1 {
		t.Fatalf("se esperaba el archivo original guardado, hay %d", n)
	}
	// Repetir la misma carga ya no es válida: choca con lo recién programado.
	if estado, cuerpo := e.enviarArchivo("/academico/importar", "horarios.csv", limpio, a); estado != http.StatusUnprocessableEntity {
		t.Fatalf("recargar lo mismo debe rechazarse por colisión: %d %s", estado, cuerpo)
	}

	// Plantilla publicada en CSV y XLSX.
	for _, f := range []string{"csv", "xlsx"} {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/academico/importar/plantilla?formato="+f, nil)
		req.Header.Set("Authorization", "Bearer "+a)
		rec := httptest.NewRecorder()
		e.app.Router.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK || rec.Body.Len() == 0 {
			t.Fatalf("plantilla %s: estado %d", f, rec.Code)
		}
	}
}
