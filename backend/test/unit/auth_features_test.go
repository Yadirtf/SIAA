// Pruebas unitarias de las funcionalidades avanzadas de autenticación:
// US-AUT-01 AC-03 (403 usuario inactivo), US-AUT-04 AC-05 (contraseñas comunes),
// US-AUT-05 (TOTP), US-AUT-07 (revocación remota), US-ROL-04 (cambio contexto) y US-ROL-05 (vigencia temporal).
package unit_test

import (
	"context"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/platform/config"
	"github.com/siaa/backend/internal/platform/security"
	"github.com/siaa/backend/internal/usecase/auth"
	"github.com/siaa/backend/internal/usecase/auth/crypto"
)

func TestAuth_InactiveUserReturns403(t *testing.T) {
	clk := shared.NewFakeClock(time.Date(2026, 9, 25, 8, 0, 0, 0, time.UTC))
	cfg := &config.Config{
		JWTSecret:           "test-secret-min-32-characters-long",
		JWTIssuer:           "siaa-test",
		JWTAccessMinutes:    15,
		JWTRefreshDays:      30,
		LockoutDurationMin:  15,
		AllowedEmailDomains: []string{"universidad.edu.co"},
	}

	inactiveUser := &user.Usuario{
		ID:           "usr-inactive",
		Correo:       "inactivo@universidad.edu.co",
		PasswordHash: "$argon2id$v=19$m=65536,t=1,p=2$...",
		Activo:       false,
		Eliminado:    false,
	}

	uRepo := &mockUsuarioRepo{usuario: inactiveUser}
	tRepo := &mockTokenRepo{}
	svc := auth.NewService(uRepo, tRepo, nil, nil, clk, cfg, nil)

	_, err := svc.Login(context.Background(), auth.LoginInput{
		Correo:   "inactivo@universidad.edu.co",
		Password: "Password1234!",
	})

	if err == nil {
		t.Fatalf("se esperaba error para usuario inactivo")
	}

	domErr, ok := err.(*shared.DomainError)
	if !ok {
		t.Fatalf("se esperaba *shared.DomainError, obtuvo %T", err)
	}

	if domErr.Code != shared.ErrUsuarioInactivo {
		t.Errorf("código de error esperado %s (HTTP 403), obtuvo %s", shared.ErrUsuarioInactivo, domErr.Code)
	}
}

func TestAuth_CommonPasswordsRejected(t *testing.T) {
	// Contraseña que cumple longitud y complejidad pero es común
	errCommon := crypto.ValidatePassword("password123456", 12)
	if errCommon == nil {
		t.Errorf("se esperaba rechazo para 'password123456'")
	}
	domErr, ok := errCommon.(*shared.DomainError)
	if !ok || len(domErr.Fields) == 0 || domErr.Fields[0].Error != "password_comun" {
		t.Errorf("se esperaba error password_comun, obtuvo: %v", errCommon)
	}

	// Contraseña robusta no común
	errRobust := crypto.ValidatePassword("X7#kL9$mQ2!wZ8@", 12)
	if errRobust != nil {
		t.Errorf("contraseña robusta fue rechazada inesperadamente: %v", errRobust)
	}
}

func TestAuth_VigenciaTemporalRoles(t *testing.T) {
	now := time.Date(2026, 9, 25, 10, 0, 0, 0, time.UTC)

	past := now.Add(-24 * time.Hour)
	future := now.Add(24 * time.Hour)

	// Rol vigente
	rolVigente := user.RolAsignado{
		Nombre:         rbac.RolDocente,
		VigenciaInicio: &past,
		VigenciaFin:    &future,
	}
	if !rolVigente.IsVigente(now) {
		t.Errorf("esperado rol vigente true")
	}

	// Rol futuro (aún no ha iniciado)
	rolFuturo := user.RolAsignado{
		Nombre:         rbac.RolCoordinador,
		VigenciaInicio: &future,
		VigenciaFin:    nil,
	}
	if rolFuturo.IsVigente(now) {
		t.Errorf("esperado rol futuro false")
	}

	// Rol vencido
	rolVencido := user.RolAsignado{
		Nombre:         rbac.RolMonitor,
		VigenciaInicio: nil,
		VigenciaFin:    &past,
	}
	if rolVencido.IsVigente(now) {
		t.Errorf("esperado rol vencido false")
	}
}

func TestAuth_CambiarContextoRol(t *testing.T) {
	clk := shared.NewFakeClock(time.Date(2026, 9, 25, 10, 0, 0, 0, time.UTC))
	cfg := &config.Config{
		JWTSecret:        "test-secret-min-32-characters-long",
		JWTIssuer:        "siaa-test",
		JWTAccessMinutes: 15,
		JWTRefreshDays:   30,
	}

	multiRoleUser := &user.Usuario{
		ID:     "usr-multi",
		Correo: "docente.coord@universidad.edu.co",
		Activo: true,
		Roles: []user.RolAsignado{
			{Nombre: rbac.RolDocente},
			{Nombre: rbac.RolCoordinador},
		},
	}

	uRepo := &mockUsuarioRepo{usuario: multiRoleUser}
	tRepo := &mockTokenRepo{}
	svc := auth.NewService(uRepo, tRepo, nil, nil, clk, cfg, nil)

	// Cambiar exitosamente a COORDINADOR
	pair, err := svc.CambiarContextoRol(context.Background(), "usr-multi", "COORDINADOR")
	if err != nil {
		t.Fatalf("CambiarContextoRol falló: %v", err)
	}

	if pair.AccessToken == "" {
		t.Errorf("se esperaba un access token nuevo")
	}

	// Intentar cambiar a un rol no asignado (SUPERADMIN)
	_, errNoAsignado := svc.CambiarContextoRol(context.Background(), "usr-multi", "SUPERADMIN")
	if errNoAsignado == nil {
		t.Fatalf("se esperaba error al solicitar rol no asignado")
	}
}

func TestAuth_RemoteSessionRevocation(t *testing.T) {
	clk := shared.NewFakeClock(time.Date(2026, 9, 25, 12, 0, 0, 0, time.UTC))
	targetUser := &user.Usuario{
		ID:     "usr-target",
		Correo: "comprometido@universidad.edu.co",
		Activo: true,
	}

	uRepo := &mockUsuarioRepo{usuario: targetUser}
	tRepo := &mockTokenRepo{}
	svc := auth.NewService(uRepo, tRepo, nil, nil, clk, &config.Config{}, nil)

	err := svc.RevocarSesionesUsuario(context.Background(), "admin-1", "usr-target", "Dispositivo reportado como robado")
	if err != nil {
		t.Fatalf("RevocarSesionesUsuario falló: %v", err)
	}

	// Verificar que el token emitido antes de la revocación sea rechazado
	tokenIssuedAt := clk.Now().Add(-5 * time.Minute)
	if !security.DefaultRevocationManager().IsTokenRevoked("usr-target", tokenIssuedAt) {
		t.Errorf("se esperaba que el token previo fuera marcado como revocado")
	}

	// Token emitido después de la revocación (si re-inicia sesión) no debe estar revocado
	newTokenIssuedAt := clk.Now().Add(5 * time.Minute)
	if security.DefaultRevocationManager().IsTokenRevoked("usr-target", newTokenIssuedAt) {
		t.Errorf("token emitido después de la revocación no debería estar revocado")
	}
}

func TestAuth_TOTPSetupAndVerify(t *testing.T) {
	clk := shared.NewFakeClock(time.Date(2026, 9, 25, 14, 0, 0, 0, time.UTC))
	cfg := &config.Config{
		JWTSecret:        "test-secret-min-32-characters-long",
		JWTIssuer:        "siaa-test",
		JWTAccessMinutes: 15,
		JWTRefreshDays:   30,
	}

	u := &user.Usuario{
		ID:     "usr-admin-totp",
		Correo: "admin@universidad.edu.co",
		Activo: true,
		Roles: []user.RolAsignado{
			{Nombre: rbac.RolAdminInst},
		},
	}

	uRepo := &mockUsuarioRepo{usuario: u}
	tRepo := &mockTokenRepo{}
	svc := auth.NewService(uRepo, tRepo, nil, nil, clk, cfg, nil)

	// 1. Setup TOTP
	setupResult, err := svc.SetupTOTP(context.Background(), u.ID)
	if err != nil {
		t.Fatalf("SetupTOTP falló: %v", err)
	}
	if setupResult.SecretKey == "" {
		t.Errorf("se esperaba una clave secreta no vacía")
	}
	if len(setupResult.BackupCodes) != 8 {
		t.Errorf("se esperaban 8 códigos de respaldo, obtuvo %d", len(setupResult.BackupCodes))
	}

	// 2. Activar con código generado válido
	code, err := crypto.GenerateTOTPCode(setupResult.SecretKey, clk.Now())
	if err != nil {
		t.Fatalf("GenerateTOTPCode falló: %v", err)
	}

	err = svc.ActivarTOTP(context.Background(), u.ID, code)
	if err != nil {
		t.Fatalf("ActivarTOTP falló: %v", err)
	}

	// 3. Verificar código correcto durante login
	pair, err := svc.VerificarTOTP(context.Background(), u.ID, code, "did-1")
	if err != nil {
		t.Fatalf("VerificarTOTP falló: %v", err)
	}
	if pair.AccessToken == "" {
		t.Errorf("se esperaba par de tokens emitido")
	}

	// 4. Verificar código de respaldo de un solo uso
	backupCode := setupResult.BackupCodes[0]
	pairBackup, err := svc.VerificarTOTP(context.Background(), u.ID, backupCode, "did-1")
	if err != nil {
		t.Fatalf("VerificarTOTP con backup code falló: %v", err)
	}
	if pairBackup.AccessToken == "" {
		t.Errorf("se esperaba par de tokens con backup code")
	}

	// Reutilizar el mismo backup code debe fallar (un solo uso)
	_, errReuse := svc.VerificarTOTP(context.Background(), u.ID, backupCode, "did-1")
	if errReuse == nil {
		t.Errorf("se esperaba error al reutilizar backup code de un solo uso")
	}
}
