package usuarios

import (
	"context"
	"strings"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/usecase/auth/crypto"
)

// CrearCmd son los datos de alta de un usuario. Sin contraseña, el usuario recibe por correo
// un enlace para definirla (mismo flujo seguro que la recuperación, US-AUT-04).
type CrearCmd struct {
	Correo    string       `json:"correo"`
	Nombre    string       `json:"nombre"`
	Apellido  string       `json:"apellido"`
	Documento string       `json:"documento"`
	Password  string       `json:"password,omitempty"`
	Roles     []RolCmd     `json:"roles"`
	Ambitos   []rbac.Scope `json:"ambitos"`
}

// Resultado del alta: el usuario y si se envió invitación por correo.
type ResultadoCreacion struct {
	Usuario           *user.Usuario
	InvitacionEnviada bool
}

// Crear registra un usuario nuevo con sus roles y ámbitos, auditado (RF-ROL-005).
func (s *Service) Crear(ctx context.Context, actor Actor, cmd CrearCmd) (*ResultadoCreacion, error) {
	u, err := s.prepararAlta(ctx, actor, cmd)
	if err != nil {
		return nil, err
	}
	if err := s.usuarios.Create(ctx, u); err != nil {
		return nil, err
	}
	s.auditar(ctx, actor, u.ID, "USUARIO_CREADO", nil, resumen(u))
	res := &ResultadoCreacion{Usuario: u}
	if cmd.Password == "" && s.invitador != nil {
		res.InvitacionEnviada = s.invitador.SolicitarRecuperacion(ctx, u.Correo) == nil
	}
	return res, nil
}

// prepararAlta valida el comando y construye el usuario sin persistirlo.
func (s *Service) prepararAlta(ctx context.Context, actor Actor, cmd CrearCmd) (*user.Usuario, error) {
	correo, err := normalizarCorreo(cmd.Correo)
	if err != nil {
		return nil, err
	}
	if err := validarNombre(cmd.Nombre, cmd.Apellido); err != nil {
		return nil, err
	}
	if existente, _ := s.usuarios.FindByCorreo(ctx, correo); existente != nil {
		return nil, &shared.DomainError{Code: shared.ErrConflictoUnicidad, Message: "Ya existe un usuario con ese correo"}
	}
	documento := strings.TrimSpace(cmd.Documento)
	if documento != "" {
		if existente, _ := s.usuarios.FindByDocumento(ctx, documento); existente != nil {
			return nil, &shared.DomainError{Code: shared.ErrConflictoUnicidad, Message: "Ya existe un usuario con ese documento"}
		}
	}
	roles, err := s.validarRoles(ctx, actor, cmd.Roles)
	if err != nil {
		return nil, err
	}
	ambitos, err := validarAmbitos(actor, cmd.Ambitos)
	if err != nil {
		return nil, err
	}
	hash, err := s.hashInicial(cmd.Password)
	if err != nil {
		return nil, err
	}
	now := s.clock.Now()
	return &user.Usuario{
		Correo:        correo,
		PasswordHash:  hash,
		Nombre:        strings.TrimSpace(cmd.Nombre),
		Apellido:      strings.TrimSpace(cmd.Apellido),
		Documento:     documento,
		Activo:        true,
		Roles:         roles,
		Ambitos:       ambitos,
		CreadoEn:      now,
		ActualizadoEn: now,
	}, nil
}

// hashInicial aplica la política de contraseñas o, sin contraseña, genera una aleatoria que
// nadie conoce: el usuario la define con el enlace de invitación.
func (s *Service) hashInicial(password string) (string, error) {
	if password == "" {
		return crypto.HashArgon2id(crypto.GenerateSecureToken(32))
	}
	if err := crypto.ValidatePassword(password, s.minClave); err != nil {
		return "", err
	}
	return crypto.HashArgon2id(password)
}

// resumen es la vista auditable del usuario (sin secretos).
func resumen(u *user.Usuario) map[string]interface{} {
	roles := make([]string, len(u.Roles))
	for i, r := range u.Roles {
		roles[i] = string(r.Nombre)
	}
	return map[string]interface{}{
		"correo": u.Correo, "nombre": u.Nombre, "apellido": u.Apellido,
		"documento": u.Documento, "activo": u.Activo, "roles": roles, "ambitos": u.Ambitos,
	}
}
