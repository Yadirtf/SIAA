// Pruebas unitarias del segundo factor TOTP (US-AUT-05).
package unit_test

import (
	"context"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/platform/config"
	"github.com/siaa/backend/internal/usecase/auth"
	"github.com/siaa/backend/internal/usecase/auth/crypto"
)

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

	// 3. El login con contraseña entrega un desafío, nunca tokens (AC-02)
	hash, _ := crypto.HashArgon2id("Clave-Admin-123*")
	u.PasswordHash = hash
	desafio := func() string {
		res, err := svc.Login(context.Background(), auth.LoginInput{Correo: u.Correo, Password: "Clave-Admin-123*"})
		if err != nil || res.Desafio == nil || res.AccessToken != "" || res.Desafio.Proposito != auth.DesafioVerificar {
			t.Fatalf("login con TOTP activo debe devolver desafío de verificación: %+v, %v", res, err)
		}
		return res.Desafio.Token
	}
	pair, err := svc.VerificarTOTP(context.Background(), desafio(), code, "did-1")
	if err != nil {
		t.Fatalf("VerificarTOTP falló: %v", err)
	}
	if pair.AccessToken == "" {
		t.Errorf("se esperaba par de tokens emitido")
	}

	// 4. Verificar código de respaldo de un solo uso
	backupCode := setupResult.BackupCodes[0]
	pairBackup, err := svc.VerificarTOTP(context.Background(), desafio(), backupCode, "did-1")
	if err != nil {
		t.Fatalf("VerificarTOTP con backup code falló: %v", err)
	}
	if pairBackup.AccessToken == "" {
		t.Errorf("se esperaba par de tokens con backup code")
	}

	// Reutilizar el mismo backup code debe fallar (un solo uso)
	_, errReuse := svc.VerificarTOTP(context.Background(), desafio(), backupCode, "did-1")
	if errReuse == nil {
		t.Errorf("se esperaba error al reutilizar backup code de un solo uso")
	}
}

// US-AUT-05: un desafío ajeno, de otro propósito o firmado con otra clave no sirve; el de
// configuración obliga a enrolar antes de recibir tokens.
func TestAuth_TOTPDesafioObligatorio(t *testing.T) {
	clk := shared.NewFakeClock(time.Date(2026, 9, 25, 14, 0, 0, 0, time.UTC))
	cfg := &config.Config{JWTSecret: "test-secret-min-32-characters-long", JWTIssuer: "siaa-test", JWTAccessMinutes: 15, JWTRefreshDays: 30}
	hash, _ := crypto.HashArgon2id("Clave-Coord-123*")
	u := &user.Usuario{ID: "usr-coord", Correo: "coord@universidad.edu.co", Activo: true, PasswordHash: hash,
		Roles: []user.RolAsignado{{Nombre: rbac.RolCoordinador}}}
	repo := &mockUsuarioRepo{usuario: u}
	svc := auth.NewService(repo, &mockTokenRepo{}, nil, &mockAuditoriaRepo{}, clk, cfg, nil)
	ctx := context.Background()

	res, err := svc.Login(ctx, auth.LoginInput{Correo: u.Correo, Password: "Clave-Coord-123*"})
	if err != nil || res.Desafio == nil || res.Desafio.Proposito != auth.DesafioConfigurar || res.AccessToken != "" {
		t.Fatalf("coordinador sin TOTP debe recibir desafío de configuración: %+v, %v", res, err)
	}
	if _, err := svc.VerificarTOTP(ctx, res.Desafio.Token, "123456", ""); err == nil {
		t.Fatal("un desafío de configuración no debe servir para verificar")
	}
	if _, err := svc.VerificarTOTP(ctx, "no-es-un-desafio", "123456", ""); err == nil {
		t.Fatal("un desafío inválido debe rechazarse")
	}
	setup, err := svc.EnrolarTOTP(ctx, res.Desafio.Token)
	if err != nil {
		t.Fatalf("EnrolarTOTP: %v", err)
	}
	code, _ := crypto.GenerateTOTPCode(setup.SecretKey, clk.Now())
	par, err := svc.ConfirmarEnrolamientoTOTP(ctx, res.Desafio.Token, code, "did-9")
	if err != nil || par.AccessToken == "" {
		t.Fatalf("ConfirmarEnrolamientoTOTP debe emitir tokens: %+v, %v", par, err)
	}
	if _, err := svc.SetupTOTP(ctx, u.ID); err == nil {
		t.Fatal("no se debe poder reconfigurar un TOTP activo")
	}
	// El desafío vence a los 5 minutos.
	res, _ = svc.Login(ctx, auth.LoginInput{Correo: u.Correo, Password: "Clave-Coord-123*"})
	tarde := auth.NewService(repo, &mockTokenRepo{}, nil, nil, shared.NewFakeClock(clk.Now().Add(6*time.Minute)), cfg, nil)
	if _, err := tarde.VerificarTOTP(ctx, res.Desafio.Token, code, ""); err == nil {
		t.Fatal("un desafío vencido debe rechazarse")
	}

	// Un docente sin TOTP entra directo (AC-05).
	u.Roles = []user.RolAsignado{{Nombre: rbac.RolDocente}}
	u.TOTPActivado = false
	res, err = svc.Login(ctx, auth.LoginInput{Correo: u.Correo, Password: "Clave-Coord-123*"})
	if err != nil || res.Desafio != nil || res.AccessToken == "" {
		t.Fatalf("docente debe recibir tokens directos: %+v, %v", res, err)
	}
}
