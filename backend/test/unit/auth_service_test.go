// Pruebas unitarias del caso de uso de autenticación.
// Usa FakeClock (ADR-03) y repositorios mock para ser deterministas.
package unit_test

import (
	"context"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/platform/config"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/usecase/auth"
)

// ─────────────────────────────────────────────────────────────
// Mocks de repositorios
// ─────────────────────────────────────────────────────────────

type mockUsuarioRepo struct {
	usuario            *user.Usuario
	err                error
	calls              []string
	lastIntentos       int
	lastBloqueadoHasta *time.Time
	lastUltimoFalloEn  *time.Time
}

func (m *mockUsuarioRepo) FindByCorreo(_ context.Context, correo string) (*user.Usuario, error) {
	m.calls = append(m.calls, "FindByCorreo:"+correo)
	return m.usuario, m.err
}
func (m *mockUsuarioRepo) FindByID(_ context.Context, id string) (*user.Usuario, error) {
	return m.usuario, m.err
}
func (m *mockUsuarioRepo) UpdateIntentosFallidos(_ context.Context, id string, intentos int, bloq *time.Time, ultimoFallo *time.Time) error {
	m.calls = append(m.calls, "UpdateIntentosFallidos")
	m.lastIntentos = intentos
	m.lastBloqueadoHasta = bloq
	m.lastUltimoFalloEn = ultimoFallo
	return nil
}
func (m *mockUsuarioRepo) ResetIntentosFallidos(_ context.Context, id string) error {
	m.calls = append(m.calls, "ResetIntentosFallidos")
	return nil
}
func (m *mockUsuarioRepo) UpdatePassword(_ context.Context, id, hash string) error {
	return nil
}
func (m *mockUsuarioRepo) Create(_ context.Context, u *user.Usuario) error {
	return nil
}
func (m *mockUsuarioRepo) Update(_ context.Context, u *user.Usuario) error {
	return nil
}

type mockTokenRepo struct {
	token   *repository.RefreshToken
	revoked []string
}

func (m *mockTokenRepo) Create(_ context.Context, t *repository.RefreshToken) error {
	return nil
}
func (m *mockTokenRepo) FindByHash(_ context.Context, hash string) (*repository.RefreshToken, error) {
	return m.token, nil
}
func (m *mockTokenRepo) RevokeByID(_ context.Context, id string) error {
	m.revoked = append(m.revoked, id)
	return nil
}
func (m *mockTokenRepo) RevokeByFamilia(_ context.Context, id string) error {
	return nil
}
func (m *mockTokenRepo) RevokeByUsuario(_ context.Context, id string) error {
	return nil
}

type mockRecoveryRepo struct{}

func (m *mockRecoveryRepo) Create(_ context.Context, t *repository.RecoveryToken) error {
	return nil
}
func (m *mockRecoveryRepo) FindByHash(_ context.Context, hash string) (*repository.RecoveryToken, error) {
	return nil, nil
}
func (m *mockRecoveryRepo) MarkUsed(_ context.Context, id string) error {
	return nil
}

type mockAuditoriaRepo struct {
	entries    int
	allEntries []*repository.AuditEntry
}

func (m *mockAuditoriaRepo) Create(_ context.Context, e *repository.AuditEntry) error {
	m.entries++
	m.allEntries = append(m.allEntries, e)
	return nil
}

type mockMailer struct {
	sentCount int
}

func (m *mockMailer) SendRecovery(_ context.Context, to, token string) error {
	m.sentCount++
	return nil
}

// ─────────────────────────────────────────────────────────────
// Helpers de prueba
// ─────────────────────────────────────────────────────────────

func defaultConfig() *config.Config {
	return &config.Config{
		JWTSecret:            "test-secret-min-32-characters-long",
		JWTIssuer:            "siaa-test",
		JWTAccessMinutes:     15,
		JWTRefreshDays:       30,
		FailedLoginMax:       5,
		FailedLoginWindowMin: 15,
		LockoutDurationMin:   15,
		PasswordMinLength:    12,
		RecoveryTokenMinutes: 30,
	}
}

func fixedClock() shared.FakeClock {
	return shared.NewFakeClock(time.Date(2024, 6, 15, 10, 0, 0, 0, time.UTC))
}

// ─────────────────────────────────────────────────────────────
// Pruebas de Login
// ─────────────────────────────────────────────────────────────

func TestLogin_CredencialesInvalidas_UsuarioNoExiste(t *testing.T) {
	usuarioRepo := &mockUsuarioRepo{usuario: nil}
	tokenRepo := &mockTokenRepo{}
	recoveryRepo := &mockRecoveryRepo{}
	auditoriaRepo := &mockAuditoriaRepo{}
	mailer := &mockMailer{}

	svc := auth.NewService(
		usuarioRepo, tokenRepo, recoveryRepo, auditoriaRepo,
		fixedClock(), defaultConfig(), mailer,
	)

	_, err := svc.Login(context.Background(), auth.LoginInput{
		Correo:   "noexiste@test.com",
		Password: "cualquier",
	})

	if err == nil {
		t.Fatal("se esperaba error, obtuvo nil")
	}

	de, ok := shared.AsDomainError(err)
	if !ok {
		t.Fatalf("se esperaba DomainError, obtuvo %T", err)
	}
	if de.Code != shared.ErrCredencialesInvalidas {
		t.Errorf("código esperado %s, obtuvo %s", shared.ErrCredencialesInvalidas, de.Code)
	}
}

func TestLogin_CuentaBloqueada(t *testing.T) {
	bloqueadoHasta := fixedClock().Now().Add(10 * time.Minute)
	usuario := &user.Usuario{
		ID:             "user-001",
		Correo:         "bloqueado@test.com",
		Activo:         true,
		BloqueadoHasta: &bloqueadoHasta,
	}

	svc := auth.NewService(
		&mockUsuarioRepo{usuario: usuario},
		&mockTokenRepo{}, &mockRecoveryRepo{}, &mockAuditoriaRepo{},
		fixedClock(), defaultConfig(), &mockMailer{},
	)

	_, err := svc.Login(context.Background(), auth.LoginInput{
		Correo:   "bloqueado@test.com",
		Password: "cualquier",
	})

	de, ok := shared.AsDomainError(err)
	if !ok || de.Code != shared.ErrCuentaBloqueada {
		t.Errorf("se esperaba ErrCuentaBloqueada, obtuvo %v", err)
	}
}

func TestLogin_IncrementaIntentosFallidosAl_PasswordIncorrecto(t *testing.T) {
	usuario := &user.Usuario{
		ID:               "user-001",
		Correo:           "docente@test.com",
		PasswordHash:     "$argon2id$v=19$m=65536,t=1,p=4$aabbccdd$eeff0011",
		Activo:           true,
		IntentosFallidos: 2,
	}

	usuarioRepo := &mockUsuarioRepo{usuario: usuario}
	svc := auth.NewService(
		usuarioRepo, &mockTokenRepo{}, &mockRecoveryRepo{}, &mockAuditoriaRepo{},
		fixedClock(), defaultConfig(), &mockMailer{},
	)

	_, err := svc.Login(context.Background(), auth.LoginInput{
		Correo:   "docente@test.com",
		Password: "wrongPassword123",
	})

	if err == nil {
		t.Fatal("se esperaba error de credenciales")
	}

	// Verificar que se llamó a UpdateIntentosFallidos
	found := false
	for _, c := range usuarioRepo.calls {
		if c == "UpdateIntentosFallidos" {
			found = true
			break
		}
	}
	if !found {
		t.Error("se esperaba llamada a UpdateIntentosFallidos")
	}
}

// ─────────────────────────────────────────────────────────────
// Pruebas de política de contraseña (función pura)
// ─────────────────────────────────────────────────────────────

func TestRecovery_SiempreRespondeIgual(t *testing.T) {
	svc := auth.NewService(
		&mockUsuarioRepo{usuario: nil}, // correo no existe
		&mockTokenRepo{}, &mockRecoveryRepo{}, &mockAuditoriaRepo{},
		fixedClock(), defaultConfig(), &mockMailer{},
	)

	// Aunque el usuario no existe, no debe retornar error
	err := svc.SolicitarRecuperacion(context.Background(), "noexiste@test.com")
	if err != nil {
		t.Errorf("recuperación debe ser silenciosa, obtuvo: %v", err)
	}
}

// ─────────────────────────────────────────────────────────────
// Pruebas de US-AUT-02: Bloqueo y desbloqueo auditado
// ─────────────────────────────────────────────────────────────

func TestLogin_BloqueoCincoIntentosConAuditoria(t *testing.T) {
	usuario := &user.Usuario{
		ID:               "user-001",
		Correo:           "docente@test.com",
		PasswordHash:     "$argon2id$v=19$m=65536,t=1,p=4$aabbccdd$eeff0011",
		Activo:           true,
		IntentosFallidos: 4,
	}

	usuarioRepo := &mockUsuarioRepo{usuario: usuario}
	auditoriaRepo := &mockAuditoriaRepo{}
	svc := auth.NewService(
		usuarioRepo, &mockTokenRepo{}, &mockRecoveryRepo{}, auditoriaRepo,
		fixedClock(), defaultConfig(), &mockMailer{},
	)

	_, err := svc.Login(context.Background(), auth.LoginInput{
		Correo:   "docente@test.com",
		Password: "wrongPassword",
	})

	if err == nil {
		t.Fatal("se esperaba error de credenciales")
	}

	if usuarioRepo.lastIntentos != 5 {
		t.Errorf("intentos esperados: 5, obtenidos: %d", usuarioRepo.lastIntentos)
	}

	if usuarioRepo.lastBloqueadoHasta == nil {
		t.Fatal("se esperaba que la cuenta quedara bloqueada tras 5 intentos")
	}

	// Verificar auditoría de bloqueo (AC-01 US-AUT-02)
	foundAudit := false
	for _, e := range auditoriaRepo.allEntries {
		if e.Accion == "BLOQUEO_CUENTA" && e.EntidadID == "user-001" {
			foundAudit = true
			break
		}
	}
	if !foundAudit {
		t.Error("se esperaba evento de auditoría BLOQUEO_CUENTA")
	}
}

func TestLogin_VentanaDeslizante_ReiniciaIntentosSiPasanMasDe15Minutos(t *testing.T) {
	clock := fixedClock()
	falloAntiguo := clock.Now().Add(-20 * time.Minute) // 20 minutos atrás (> 15 min)
	usuario := &user.Usuario{
		ID:               "user-001",
		Correo:           "docente@test.com",
		PasswordHash:     "$argon2id$v=19$m=65536,t=1,p=4$aabbccdd$eeff0011",
		Activo:           true,
		IntentosFallidos: 4,
		UltimoFalloEn:    &falloAntiguo,
	}

	usuarioRepo := &mockUsuarioRepo{usuario: usuario}
	auditoriaRepo := &mockAuditoriaRepo{}
	svc := auth.NewService(
		usuarioRepo, &mockTokenRepo{}, &mockRecoveryRepo{}, auditoriaRepo,
		clock, defaultConfig(), &mockMailer{},
	)

	_, err := svc.Login(context.Background(), auth.LoginInput{
		Correo:   "docente@test.com",
		Password: "wrongPassword",
	})

	if err == nil {
		t.Fatal("se esperaba error de credenciales")
	}

	// Al haber transcurrido más de 15 min, la ventana deslizante reinicia a 1
	if usuarioRepo.lastIntentos != 1 {
		t.Errorf("intentos esperados: 1 (reinicio por ventana deslizante), obtenidos: %d", usuarioRepo.lastIntentos)
	}

	if usuarioRepo.lastBloqueadoHasta != nil {
		t.Error("la cuenta NO debería estar bloqueada")
	}
}

func TestAuth_DesbloqueoAdministrativoAuditado(t *testing.T) {
	bloqueado := fixedClock().Now().Add(10 * time.Minute)
	usuario := &user.Usuario{
		ID:               "user-001",
		Correo:           "bloqueado@test.com",
		Activo:           true,
		IntentosFallidos: 5,
		BloqueadoHasta:   &bloqueado,
	}

	usuarioRepo := &mockUsuarioRepo{usuario: usuario}
	auditoriaRepo := &mockAuditoriaRepo{}
	svc := auth.NewService(
		usuarioRepo, &mockTokenRepo{}, &mockRecoveryRepo{}, auditoriaRepo,
		fixedClock(), defaultConfig(), &mockMailer{},
	)

	err := svc.DesbloquearCuenta(context.Background(), "admin-007", "user-001")
	if err != nil {
		t.Fatalf("desbloqueo no debería fallar: %v", err)
	}

	// Verificar llamada a ResetIntentosFallidos
	foundReset := false
	for _, c := range usuarioRepo.calls {
		if c == "ResetIntentosFallidos" {
			foundReset = true
			break
		}
	}
	if !foundReset {
		t.Error("se esperaba llamada a ResetIntentosFallidos")
	}

	// Verificar auditoría con actor administrativo (AC-02 US-AUT-02)
	foundAudit := false
	for _, e := range auditoriaRepo.allEntries {
		if e.Accion == "DESBLOQUEO_CUENTA" && e.ActorID == "admin-007" && e.EntidadID == "user-001" {
			foundAudit = true
			break
		}
	}
	if !foundAudit {
		t.Error("se esperaba evento de auditoría DESBLOQUEO_CUENTA con admin-007")
	}
}

func TestAuth_DesbloqueoUsuarioNoExiste(t *testing.T) {
	usuarioRepo := &mockUsuarioRepo{usuario: nil}
	svc := auth.NewService(
		usuarioRepo, &mockTokenRepo{}, &mockRecoveryRepo{}, &mockAuditoriaRepo{},
		fixedClock(), defaultConfig(), &mockMailer{},
	)

	err := svc.DesbloquearCuenta(context.Background(), "admin-007", "no-existe")
	if err == nil {
		t.Fatal("se esperaba error de usuario no encontrado")
	}
}
