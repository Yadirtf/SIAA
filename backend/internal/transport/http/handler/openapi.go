// Package handler — manejador para la especificación OpenAPI 3.1.
// US-PLT-01 AC-06, T-PLT-01.9.
package handler

import (
	"net/http"
	"os"

	"github.com/labstack/echo/v4"
)

// OpenAPIHandler expone la especificación OpenAPI 3.1 en formato JSON.
type OpenAPIHandler struct {
	specPath string
}

// NewOpenAPIHandler crea una nueva instancia de OpenAPIHandler.
func NewOpenAPIHandler(specPath string) *OpenAPIHandler {
	return &OpenAPIHandler{specPath: specPath}
}

// Spec entrega el archivo openapi.json.
func (h *OpenAPIHandler) Spec(c echo.Context) error {
	data, err := os.ReadFile(h.specPath)
	if err != nil {
		// Rutas relativas alternativas según el contexto de ejecución
		backups := []string{
			"../contracts/openapi.json",
			"../../contracts/openapi.json",
			"../../../contracts/openapi.json",
			"contracts/openapi.json",
		}
		for _, b := range backups {
			if d, e := os.ReadFile(b); e == nil {
				data = d
				err = nil
				break
			}
		}
	}
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "Especificación OpenAPI no disponible")
	}

	return c.Blob(http.StatusOK, "application/json; charset=utf-8", data)
}
