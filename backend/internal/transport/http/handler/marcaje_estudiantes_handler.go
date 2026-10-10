package handler

import (
	"errors"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/transport/http/dto"
	"github.com/siaa/backend/internal/transport/http/middleware"
	usecaseMarcaje "github.com/siaa/backend/internal/usecase/marcaje"
)

// WithAsistenciaEstudiante habilita el porcentaje de asistencia del estudiante (US-MAR-13 AC-05).
func (h *MarcajeAdminHandler) WithAsistenciaEstudiante(uc *usecaseMarcaje.AsistenciaEstudianteUseCase) *MarcajeAdminHandler {
	h.asistenciaUC = uc
	return h
}

// VentanaEstudiantil abre la ventana de marcaje para los estudiantes del grupo (US-MAR-13).
// POST /api/v1/sesiones/:id/ventana-estudiantil
func (h *MarcajeAdminHandler) VentanaEstudiantil(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}
	var req dto.VentanaEstudiantilRequest
	_ = c.Bind(&req)
	cierraEn, err := h.estudianteUC.AbrirVentana(c.Request().Context(), c.Param("id"), claims.UsuarioID, req.DuracionMinutos)
	if err != nil {
		return errorMarcajeEstudiantil(err)
	}
	return c.JSON(http.StatusOK, map[string]interface{}{"abierta": true, "cierraEn": cierraEn.Format(time.RFC3339)})
}

// CerrarVentanaEstudiantil termina el marcaje de estudiantes antes de tiempo (US-MAR-13 AC-04).
// DELETE /api/v1/sesiones/:id/ventana-estudiantil
func (h *MarcajeAdminHandler) CerrarVentanaEstudiantil(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}
	cerradaEn, err := h.estudianteUC.CerrarVentana(c.Request().Context(), c.Param("id"), claims.UsuarioID)
	if err != nil {
		return errorMarcajeEstudiantil(err)
	}
	return c.JSON(http.StatusOK, map[string]interface{}{"abierta": false, "cierraEn": cerradaEn.Format(time.RFC3339)})
}

// ConsultarListaManual devuelve a los estudiantes del grupo con su registro actual (US-MAR-14 AC-01).
// GET /api/v1/sesiones/:id/lista-manual
func (h *MarcajeAdminHandler) ConsultarListaManual(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}
	lista, err := h.listaManualUC.Consultar(c.Request().Context(), c.Param("id"), claims.UsuarioID)
	if err != nil {
		return errorMarcajeEstudiantil(err)
	}
	return c.JSON(http.StatusOK, lista)
}

// ListaManual procesa el pase de lista de contingencia por el docente (US-MAR-14).
// POST /api/v1/sesiones/:id/lista-manual
func (h *MarcajeAdminHandler) ListaManual(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}
	var req dto.ListaManualRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Cuerpo inválido")
	}
	items := make([]usecaseMarcaje.ItemListaEstudiante, len(req.Estudiantes))
	for i, est := range req.Estudiantes {
		items[i] = usecaseMarcaje.ItemListaEstudiante{EstudianteID: est.EstudianteID, Presente: est.Presente}
	}
	res, err := h.listaManualUC.Registrar(c.Request().Context(), c.Param("id"), claims.UsuarioID, req.Motivo, items)
	if err != nil {
		if errors.Is(err, usecaseMarcaje.ErrMotivoListaRequerido) {
			return shared.NewValidationError(err.Error(), shared.FieldError{Campo: "motivo", Error: "requerido"})
		}
		return errorMarcajeEstudiantil(err)
	}
	return c.JSON(http.StatusOK, map[string]interface{}{
		"mensaje":      "Lista manual registrada y auditada",
		"registrados":  res.Registrados,
		"conservados":  res.Conservados,
		"noPertenecen": res.NoPertenecen,
	})
}

// MiAsistencia devuelve el porcentaje acumulado del estudiante por asignatura (US-MAR-13 AC-05).
// GET /api/v1/me/asistencia
func (h *MarcajeAdminHandler) MiAsistencia(c echo.Context) error {
	claims, ok := middleware.GetClaims(c)
	if !ok {
		return shared.NewAuthError(shared.ErrTokenExpirado, "Autenticación requerida")
	}
	if h.asistenciaUC == nil {
		return c.JSON(http.StatusOK, []usecaseMarcaje.AsistenciaDTO{})
	}
	lista, err := h.asistenciaUC.DelEstudiante(c.Request().Context(), claims.UsuarioID)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, lista)
}

func errorMarcajeEstudiantil(err error) error {
	if errors.Is(err, usecaseMarcaje.ErrDocenteNoAutorizado) {
		return echo.NewHTTPError(http.StatusForbidden, err.Error())
	}
	// El manejador central traduce los errores de dominio y oculta los internos.
	return err
}
