// Package unit_test — pruebas de control de acceso por permisos granulares (RBAC).
// US-ROL-01: AC-01..AC-06, T-ROL-01.3, T-ROL-01.4, T-ROL-01.6, T-ROL-01.8.
package unit_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	apphttp "github.com/siaa/backend/internal/transport/http"
	"github.com/siaa/backend/internal/transport/http/handler"
	"github.com/siaa/backend/internal/transport/http/middleware"
	"github.com/siaa/backend/internal/usecase/auth"
)

// ─────────────────────────────────────────────────────────────
// AC-03 / T-ROL-01.4: Verificación estricta de rutas al arranque
// ─────────────────────────────────────────────────────────────

func TestStartupRouteVerification_FallaConRutaSinPermisoNiMarcaPublica(t *testing.T) {
	e := echo.New()
	registry := apphttp.NewRouteRegistry()

	// Registrar ruta huérfana en Echo sin declararla en registry
	e.GET("/api/v1/recurso/desprotegido", func(c echo.Context) error {
		return c.String(http.StatusOK, "ok")
	})

	err := registry.VerifyAllRoutes(e)
	if err == nil {
		t.Fatal("se esperaba error de arranque por ruta sin permiso ni marca pública (AC-03 / T-ROL-01.4)")
	}

	// Al marcarla pública, debe pasar la verificación
	registry.MarkPublic(http.MethodGet, "/api/v1/recurso/desprotegido")
	if err := registry.VerifyAllRoutes(e); err != nil {
		t.Fatalf("al estar marcada pública no debe fallar: %v", err)
	}

	// Al agregar otra ruta protegida sin registrar, vuelve a fallar
	e.POST("/api/v1/recurso/nuevo", func(c echo.Context) error {
		return c.String(http.StatusOK, "ok")
	})
	if err := registry.VerifyAllRoutes(e); err == nil {
		t.Fatal("se esperaba fallo ante nueva ruta protegida no registrada en registry")
	}

	// Al registrar el permiso, pasa
	registry.RegisterPermission(http.MethodPost, "/api/v1/recurso/nuevo", rbac.PermAulaCrear)
	if err := registry.VerifyAllRoutes(e); err != nil {
		t.Fatalf("con permiso registrado no debe fallar: %v", err)
	}
}

// ─────────────────────────────────────────────────────────────
// AC-02 / T-ROL-01.6: Intento denegado genera 403 y se audita
// ─────────────────────────────────────────────────────────────

func TestRequirePermission_AuditaAccesoDenegadoCon403(t *testing.T) {
	e := echo.New()
	auditoriaRepo := &mockAuditoriaRepo{}

	protectedHandler := func(c echo.Context) error {
		return c.String(http.StatusOK, "exito")
	}

	// Proteger con permiso aula:crear
	mwProtected := middleware.RequirePermission(rbac.PermAulaCrear, auditoriaRepo)
	handlerWithMw := mwProtected(protectedHandler)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/aulas", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	// Usuario con rol Docente (no tiene aula:crear)
	claims := &auth.JWTClaims{
		UsuarioID: "docente-001",
		RolActivo: "DOCENTE",
		Permisos: []string{
			string(rbac.PermMarcajeCrear),
			string(rbac.PermMarcajeLeer),
		},
	}
	c.Set(middleware.CtxClaims, claims)

	err := handlerWithMw(c)
	if err == nil {
		t.Fatal("se esperaba error de autorización 403")
	}

	de, ok := shared.AsDomainError(err)
	if !ok || de.Code != shared.ErrPermisosDenegados {
		t.Fatalf("se esperaba ErrPermisosDenegados, obtuvo: %v", err)
	}

	// Verificar que el intento quedó registrado en auditoría (AC-02, T-ROL-01.6)
	if len(auditoriaRepo.allEntries) != 1 {
		t.Fatalf("se esperaba 1 registro de auditoría, se obtuvieron %d", len(auditoriaRepo.allEntries))
	}

	entry := auditoriaRepo.allEntries[0]
	if entry.Accion != "ACCESO_DENEGADO" {
		t.Errorf("accion esperada ACCESO_DENEGADO, obtuvo %s", entry.Accion)
	}
	if entry.ActorID != "docente-001" {
		t.Errorf("actor esperado docente-001, obtuvo %s", entry.ActorID)
	}

	valMap, ok := entry.ValorNuevo.(map[string]string)
	if !ok || valMap["permiso_requerido"] != string(rbac.PermAulaCrear) {
		t.Errorf("permiso_requerido esperado aula:crear, obtuvo %v", entry.ValorNuevo)
	}
}

// ─────────────────────────────────────────────────────────────
// AC-01: Listar roles predefinidos con matriz de permisos SRS §3.2
// ─────────────────────────────────────────────────────────────

func TestRoles_ListarRolesPredefinidos(t *testing.T) {
	e := echo.New()
	rolesH := handler.NewRolesHandler()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/roles", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	err := rolesH.ListarRoles(c)
	if err != nil {
		t.Fatalf("ListarRoles retornó error: %v", err)
	}
	if rec.Code != http.StatusOK {
		t.Fatalf("status esperado 200, obtuvo %d", rec.Code)
	}

	var roles []handler.RoleDTO
	if err := json.Unmarshal(rec.Body.Bytes(), &roles); err != nil {
		t.Fatalf("cuerpo no es JSON válido: %v", err)
	}

	if len(roles) != 7 {
		t.Fatalf("se esperaban 7 roles predefinidos, se obtuvieron %d", len(roles))
	}

	// Verificar que cada rol predefinido tiene su conjunto exacto de permisos
	for _, r := range roles {
		expectedPerms := rbac.DefaultPermissions[rbac.RoleName(r.Nombre)]
		if len(r.Permisos) != len(expectedPerms) {
			t.Errorf("rol %s: cantidad de permisos esperada %d, obtenida %d",
				r.Nombre, len(expectedPerms), len(r.Permisos))
		}
	}
}

// ─────────────────────────────────────────────────────────────
// AC-04: Restricciones específicas para Docente
// ─────────────────────────────────────────────────────────────

func TestRBAC_DocenteRestriccionesEspecificas(t *testing.T) {
	docentePerms := rbac.DefaultPermissions[rbac.RolDocente]

	// AC-04: Un docente siempre recibe 403 ante marcaje:anular, aula:editar-geometria y parametro:editar
	prohibidos := []rbac.Permission{
		rbac.PermMarcajeAnular,
		rbac.PermAulaEditarGeometria,
		rbac.PermParametroEditar,
		rbac.PermAulaEliminar,
		rbac.PermSedeAdministrar,
		rbac.PermUsuarioCrear,
	}

	for _, p := range prohibidos {
		if rbac.HasPermission(docentePerms, p) {
			t.Errorf("AC-04 violado: Docente NO debe tener el permiso %s", p)
		}
	}

	// Permisos legítimos de Docente
	permitidos := []rbac.Permission{
		rbac.PermMarcajeCrear,
		rbac.PermMarcajeLeer,
		rbac.PermHorarioLeer,
		rbac.PermJustificacionCrear,
		rbac.PermJustificacionLeer,
	}

	for _, p := range permitidos {
		if !rbac.HasPermission(docentePerms, p) {
			t.Errorf("Docente debe poseer el permiso %s", p)
		}
	}
}

// ─────────────────────────────────────────────────────────────
// AC-05: Permisos y restricciones de Auditor
// ─────────────────────────────────────────────────────────────

func TestRBAC_AuditorPermisosYRestricciones(t *testing.T) {
	auditorPerms := rbac.DefaultPermissions[rbac.RolAuditor]

	// AC-05: Auditor puede leer y exportar
	lecturasPermitidas := []rbac.Permission{
		rbac.PermMarcajeLeer,
		rbac.PermAulaLeer,
		rbac.PermHorarioLeer,
		rbac.PermJustificacionLeer,
		rbac.PermReporteExportar,
		rbac.PermReporteLeer,
		rbac.PermAuditoriaLeer,
	}

	for _, p := range lecturasPermitidas {
		if !rbac.HasPermission(auditorPerms, p) {
			t.Errorf("AC-05 violado: Auditor debe tener permiso de lectura/exportación %s", p)
		}
	}

	// AC-05: Cualquier operación de escritura sobre datos operativos devuelve 403
	escriturasProhibidas := []rbac.Permission{
		rbac.PermMarcajeCrear,
		rbac.PermMarcajeAjustar,
		rbac.PermMarcajeAnular,
		rbac.PermAulaCrear,
		rbac.PermAulaEditar,
		rbac.PermAulaEditarGeometria,
		rbac.PermAulaEliminar,
		rbac.PermParametroEditar,
		rbac.PermUsuarioCrear,
		rbac.PermUsuarioEditar,
		rbac.PermUsuarioEliminar,
		rbac.PermJustificacionAprobar,
	}

	for _, p := range escriturasProhibidas {
		if rbac.HasPermission(auditorPerms, p) {
			t.Errorf("AC-05 violado: Auditor NO debe tener permiso de escritura operativa %s", p)
		}
	}
}

// ─────────────────────────────────────────────────────────────
// T-ROL-01.8: Matriz de pruebas rol × endpoint data-driven
// ─────────────────────────────────────────────────────────────

func TestRBAC_MatrizCompletaSRS32_DataDriven(t *testing.T) {
	type testCase struct {
		rol       rbac.RoleName
		permiso   rbac.Permission
		debeTener bool
	}

	cases := []testCase{
		// Superadmin: acceso total a operaciones críticas
		{rbac.RolSuperadmin, rbac.PermMarcajeAnular, true},
		{rbac.RolSuperadmin, rbac.PermAulaEditarGeometria, true},
		{rbac.RolSuperadmin, rbac.PermParametroEditar, true},
		{rbac.RolSuperadmin, rbac.PermRolCrear, true},

		// Coordinador: gestión académica y justificaciones pero no alterar geometría
		{rbac.RolCoordinador, rbac.PermJustificacionAprobar, true},
		{rbac.RolCoordinador, rbac.PermHorarioCrear, true},
		{rbac.RolCoordinador, rbac.PermAulaEditarGeometria, false},
		{rbac.RolCoordinador, rbac.PermParametroEditar, false},

		// Estudiante: solo marcaje y consulta de horarios
		{rbac.RolEstudiante, rbac.PermMarcajeCrear, true},
		{rbac.RolEstudiante, rbac.PermHorarioLeer, true},
		{rbac.RolEstudiante, rbac.PermJustificacionAprobar, false},
		{rbac.RolEstudiante, rbac.PermReporteExportar, false},

		// Monitor: solo lectura de marcaje, horarios y reportes
		{rbac.RolMonitor, rbac.PermMarcajeLeer, true},
		{rbac.RolMonitor, rbac.PermReporteLeer, true},
		{rbac.RolMonitor, rbac.PermMarcajeCrear, false},
		{rbac.RolMonitor, rbac.PermParametroEditar, false},
	}

	for _, tc := range cases {
		perms := rbac.DefaultPermissions[tc.rol]
		tiene := rbac.HasPermission(perms, tc.permiso)
		if tiene != tc.debeTener {
			t.Errorf("rol %s con permiso %s: esperado %v, obtenido %v",
				tc.rol, tc.permiso, tc.debeTener, tiene)
		}
	}
}
