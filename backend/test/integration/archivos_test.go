package integration

import (
	"bytes"
	"encoding/json"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
)

// soporte es un archivo adjunto de una solicitud multipart.
type soporte struct {
	nombre    string
	contenido []byte
}

// enviarMultipart envía un formulario con campos y soportes y decodifica la respuesta JSON.
func (e *entorno) enviarMultipart(ruta string, campos map[string]string, soportes []soporte, token string) (int, map[string]interface{}) {
	e.t.Helper()
	var cuerpo bytes.Buffer
	w := multipart.NewWriter(&cuerpo)
	for k, v := range campos {
		_ = w.WriteField(k, v)
	}
	for _, s := range soportes {
		parte, err := w.CreateFormFile("soportes", s.nombre)
		if err != nil {
			e.t.Fatalf("crear parte multipart: %v", err)
		}
		_, _ = parte.Write(s.contenido)
	}
	_ = w.Close()
	req := httptest.NewRequest(http.MethodPost, "/api/v1"+ruta, &cuerpo)
	req.Header.Set("Content-Type", w.FormDataContentType())
	req.Header.Set("Authorization", "Bearer "+token)
	rec := httptest.NewRecorder()
	e.app.Router.ServeHTTP(rec, req)
	var datos map[string]interface{}
	_ = json.Unmarshal(rec.Body.Bytes(), &datos)
	if rec.Code >= http.StatusInternalServerError {
		e.t.Fatalf("POST %s: error interno %d: %s", ruta, rec.Code, rec.Body.String())
	}
	return rec.Code, datos
}

// descargar obtiene un archivo binario y exige el estado esperado.
func (e *entorno) descargar(ruta, token string, esperado int) *httptest.ResponseRecorder {
	e.t.Helper()
	req := httptest.NewRequest(http.MethodGet, "/api/v1"+ruta, nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rec := httptest.NewRecorder()
	e.app.Router.ServeHTTP(rec, req)
	if rec.Code != esperado {
		e.t.Fatalf("GET %s: estado %d, esperado %d: %s", ruta, rec.Code, esperado, rec.Body.String())
	}
	return rec
}
