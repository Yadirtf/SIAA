// Package unit — pruebas unitarias para US-AUT-03 (Vinculación de dispositivo confiable).
// AC-01..AC-06, T-AUT-03.1..T-AUT-03.9.
package unit

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"

	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/platform/clock"
	"github.com/siaa/backend/internal/platform/config"
	"github.com/siaa/backend/internal/repository"
	"github.com/siaa/backend/internal/usecase/auth"
)

type mockDispositivoRepo struct {
	dispositivos map[string]*user.Dispositivo
}

func newMockDispositivoRepo() *mockDispositivoRepo {
	return &mockDispositivoRepo{dispositivos: make(map[string]*user.Dispositivo)}
}

func (m *mockDispositivoRepo) FindByID(ctx context.Context, id string) (*user.Dispositivo, error) {
	d, ok := m.dispositivos[id]
	if !ok {
		return nil, nil
	}
	return d, nil
}

func (m *mockDispositivoRepo) FindByInstalacion(ctx context.Context, usuarioID, instalacionID string) (*user.Dispositivo, error) {
	for _, d := range m.dispositivos {
		if d.UsuarioID == usuarioID && d.InstalacionID == instalacionID {
			return d, nil
		}
	}
	return nil, nil
}

func (m *mockDispositivoRepo) Create(ctx context.Context, d *user.Dispositivo) error {
	m.dispositivos[d.ID] = d
	return nil
}

func (m *mockDispositivoRepo) FindByUsuario(ctx context.Context, usuarioID string) ([]*user.Dispositivo, error) {
	var res []*user.Dispositivo
	for _, d := range m.dispositivos {
		if d.UsuarioID == usuarioID {
			res = append(res, d)
		}
	}
	return res, nil
}

func (m *mockDispositivoRepo) FindRecentByInstalacion(ctx context.Context, instalacionID string, desde time.Time) ([]*user.Dispositivo, error) {
	var res []*user.Dispositivo
	for _, d := range m.dispositivos {
		if d.InstalacionID == instalacionID && (d.CreadoEn.After(desde) || d.CreadoEn.Equal(desde)) {
			res = append(res, d)
		}
	}
	return res, nil
}

func (m *mockDispositivoRepo) Update(ctx context.Context, d *user.Dispositivo) error {
	m.dispositivos[d.ID] = d
	return nil
}

type mockUserRepoForDevice struct {
	usuarios map[string]*user.Usuario
}

func newMockUserRepoForDevice() *mockUserRepoForDevice {
	return &mockUserRepoForDevice{usuarios: make(map[string]*user.Usuario)}
}

func (m *mockUserRepoForDevice) FindByCorreo(ctx context.Context, correo string) (*user.Usuario, error) {
	for _, u := range m.usuarios {
		if u.Correo == correo {
			return u, nil
		}
	}
	return nil, nil
}

func (m *mockUserRepoForDevice) FindByID(ctx context.Context, id string) (*user.Usuario, error) {
	return m.usuarios[id], nil
}

func (m *mockUserRepoForDevice) UpdateIntentosFallidos(ctx context.Context, id string, intentos int, b *time.Time, u *time.Time) error {
	return nil
}

func (m *mockUserRepoForDevice) ResetIntentosFallidos(ctx context.Context, id string) error {
	return nil
}

func (m *mockUserRepoForDevice) UpdatePassword(ctx context.Context, id, passwordHash string) error {
	return nil
}

func (m *mockUserRepoForDevice) Create(ctx context.Context, u *user.Usuario) error {
	m.usuarios[u.ID] = u
	return nil
}

func (m *mockUserRepoForDevice) Update(ctx context.Context, u *user.Usuario) error {
	m.usuarios[u.ID] = u
	return nil
}

func (m *mockUserRepoForDevice) Listar(ctx context.Context, limite int) ([]*user.Usuario, error) {
	var list []*user.Usuario
	for _, u := range m.usuarios {
		list = append(list, u)
	}
	return list, nil
}

type mockAuditRepoForDevice struct {
	entries []*repository.AuditEntry
}

func (m *mockAuditRepoForDevice) Create(ctx context.Context, entry *repository.AuditEntry) error {
	m.entries = append(m.entries, entry)
	return nil
}

// AC-01: Primer dispositivo queda vinculado como confiable automáticamente.
func TestDispositivo_PrimerDispositivo_ConfiableAutomatico(t *testing.T) {
	ctx := context.Background()
	userRepo := newMockUserRepoForDevice()
	dispRepo := newMockDispositivoRepo()
	auditRepo := &mockAuditRepoForDevice{}

	u := &user.Usuario{ID: "usr-1", Correo: "docente@institucion.edu.co", Activo: true}
	_ = userRepo.Create(ctx, u)

	svc := auth.NewService(
		userRepo,
		nil,
		nil,
		auditRepo,
		clock.RealClock{},
		&config.Config{},
		nil,
	).WithDispositivos(dispRepo)

	input := auth.RegistrarDispositivoInput{
		UsuarioID:     "usr-1",
		InstalacionID: "uuid-device-1",
		Modelo:        "Pixel 7",
		SO:            "Android 14",
		VersionApp:    "1.0.0",
	}

	d, err := svc.RegistrarDispositivo(ctx, input)
	assert.NoError(t, err)
	assert.NotNil(t, d)
	assert.True(t, d.Confiable, "el primer dispositivo debe ser confiable")
	assert.False(t, d.PendienteAprobacion, "no debe estar pendiente de aprobación")
	assert.True(t, d.EsValidoParaMarcaje())

	// Verificar que el usuario quedó con dispositivo vinculado
	actualizado, _ := userRepo.FindByID(ctx, "usr-1")
	assert.NotNil(t, actualizado.DispositivoVinculado)
	assert.Equal(t, "uuid-device-1", *actualizado.DispositivoVinculado)
}

// AC-03 / AC-05: Segundo dispositivo requiere aprobación administrativa.
func TestDispositivo_SegundoDispositivo_RequiereAprobacion(t *testing.T) {
	ctx := context.Background()
	userRepo := newMockUserRepoForDevice()
	dispRepo := newMockDispositivoRepo()
	auditRepo := &mockAuditRepoForDevice{}

	u := &user.Usuario{ID: "usr-1", Correo: "docente@institucion.edu.co", Activo: true}
	_ = userRepo.Create(ctx, u)

	svc := auth.NewService(
		userRepo,
		nil,
		nil,
		auditRepo,
		clock.RealClock{},
		&config.Config{},
		nil,
	).WithDispositivos(dispRepo)

	// Primer dispositivo
	_, _ = svc.RegistrarDispositivo(ctx, auth.RegistrarDispositivoInput{
		UsuarioID:     "usr-1",
		InstalacionID: "uuid-device-1",
		Modelo:        "Pixel 7",
		SO:            "Android 14",
		VersionApp:    "1.0.0",
	})

	// Segundo dispositivo (ej. cambio de teléfono o reinstalación AC-05)
	d2, err := svc.RegistrarDispositivo(ctx, auth.RegistrarDispositivoInput{
		UsuarioID:     "usr-1",
		InstalacionID: "uuid-device-2",
		Modelo:        "Galaxy S23",
		SO:            "Android 14",
		VersionApp:    "1.0.0",
	})

	assert.NoError(t, err)
	assert.NotNil(t, d2)
	assert.False(t, d2.Confiable, "el segundo dispositivo no debe ser confiable de inmediato")
	assert.True(t, d2.PendienteAprobacion, "debe requerir aprobación administrativa")
	assert.False(t, d2.EsValidoParaMarcaje())
}

// AC-04 / T-AUT-03.7: Mismo dispositivo usado por usuarios distintos en 24h genera alerta de anomalía R-03.
func TestDispositivo_AnomaliaR03_MismoDispositivoVariosUsuarios(t *testing.T) {
	ctx := context.Background()
	userRepo := newMockUserRepoForDevice()
	dispRepo := newMockDispositivoRepo()
	auditRepo := &mockAuditRepoForDevice{}

	_ = userRepo.Create(ctx, &user.Usuario{ID: "usr-1", Correo: "docente1@institucion.edu.co", Activo: true})
	_ = userRepo.Create(ctx, &user.Usuario{ID: "usr-2", Correo: "docente2@institucion.edu.co", Activo: true})

	svc := auth.NewService(
		userRepo,
		nil,
		nil,
		auditRepo,
		clock.RealClock{},
		&config.Config{},
		nil,
	).WithDispositivos(dispRepo)

	// Docente 1 registra el teléfono
	_, _ = svc.RegistrarDispositivo(ctx, auth.RegistrarDispositivoInput{
		UsuarioID:     "usr-1",
		InstalacionID: "uuid-compartido",
		Modelo:        "Xiaomi Redmi",
		SO:            "Android 13",
		VersionApp:    "1.0.0",
	})

	// Docente 2 intenta registrar el MISMO teléfono en la misma jornada
	_, err := svc.RegistrarDispositivo(ctx, auth.RegistrarDispositivoInput{
		UsuarioID:     "usr-2",
		InstalacionID: "uuid-compartido",
		Modelo:        "Xiaomi Redmi",
		SO:            "Android 13",
		VersionApp:    "1.0.0",
	})

	assert.NoError(t, err)

	// Verificar que se emitió la alerta en auditoría
	encontroAlerta := false
	for _, a := range auditRepo.entries {
		if a.Accion == "ALERTA_ANOMALIA_DISPOSITIVO_COMPARTIDO" {
			encontroAlerta = true
			break
		}
	}
	assert.True(t, encontroAlerta, "debe registrarse alerta de anomalía R-03")
}

// AC-03 / AC-06: Aprobación y revocación administrativa.
func TestDispositivo_AprobacionYRevocacion(t *testing.T) {
	ctx := context.Background()
	userRepo := newMockUserRepoForDevice()
	dispRepo := newMockDispositivoRepo()
	auditRepo := &mockAuditRepoForDevice{}

	_ = userRepo.Create(ctx, &user.Usuario{ID: "usr-1", Correo: "docente@institucion.edu.co", Activo: true})

	svc := auth.NewService(
		userRepo,
		nil,
		nil,
		auditRepo,
		clock.RealClock{},
		&config.Config{},
		nil,
	).WithDispositivos(dispRepo)

	// Dispositivo 1 (activo)
	d1, _ := svc.RegistrarDispositivo(ctx, auth.RegistrarDispositivoInput{
		UsuarioID:     "usr-1",
		InstalacionID: "dev-antiguo",
	})

	// Dispositivo 2 (pendiente)
	d2, _ := svc.RegistrarDispositivo(ctx, auth.RegistrarDispositivoInput{
		UsuarioID:     "usr-1",
		InstalacionID: "dev-nuevo",
	})

	// Admin aprueba dispositivo 2
	err := svc.AprobarDispositivo(ctx, "admin-1", d2.ID)
	assert.NoError(t, err)

	// Dispositivo 2 ahora debe ser confiable y no pendiente
	d2Actualizado, _ := dispRepo.FindByID(ctx, d2.ID)
	assert.True(t, d2Actualizado.Confiable)
	assert.False(t, d2Actualizado.PendienteAprobacion)

	// Dispositivo 1 debe quedar revocado automáticamente
	d1Actualizado, _ := dispRepo.FindByID(ctx, d1.ID)
	assert.False(t, d1Actualizado.Confiable)

	// Admin revoca dispositivo 2
	err = svc.RevocarDispositivo(ctx, "admin-1", d2.ID)
	assert.NoError(t, err)

	d2Revocado, _ := dispRepo.FindByID(ctx, d2.ID)
	assert.False(t, d2Revocado.Confiable)
	assert.NotNil(t, d2Revocado.RevocadoEn)
}
