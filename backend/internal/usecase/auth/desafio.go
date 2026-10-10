// Package auth — desafío de segundo factor emitido tras validar la contraseña.
// US-AUT-05 AC-01/AC-02: el login de un rol administrativo (o de quien activó TOTP) no
// entrega tokens; entrega un desafío de corta vida que solo sirve para presentar el código
// TOTP o para configurarlo. Así el segundo factor nunca se puede saltar sin contraseña.
package auth

import (
	"context"
	"crypto/sha256"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
)

// Propósitos del desafío.
const (
	DesafioVerificar  = "VERIFICAR_TOTP"
	DesafioConfigurar = "CONFIGURAR_TOTP"
)

// vigenciaDesafio es el tiempo que tiene el usuario para completar el segundo factor.
const vigenciaDesafio = 5 * time.Minute

// DesafioTOTP es la respuesta del login cuando falta el segundo factor.
type DesafioTOTP struct {
	Token     string
	Proposito string
	ExpiraEn  time.Time
}

type desafioClaims struct {
	jwt.RegisteredClaims
	UsuarioID     string `json:"uid"`
	Proposito     string `json:"pro"`
	DispositivoID string `json:"did,omitempty"`
}

// requiereSegundoFactor aplica AC-01/AC-05: roles administrativos vigentes siempre; los
// operativos solo si activaron TOTP voluntariamente.
func requiereSegundoFactor(u *user.Usuario, now time.Time) bool {
	if u.TOTPActivado {
		return true
	}
	for _, r := range u.Roles {
		if r.IsVigente(now) && IsRolAdministrativo(r.Nombre) {
			return true
		}
	}
	return false
}

// claveDesafio deriva una clave distinta a la de los access tokens, de modo que un desafío
// nunca sea aceptado por el middleware JWT como credencial de acceso.
func (s *Service) claveDesafio() []byte {
	h := sha256.Sum256([]byte(s.cfg.JWTSecret + "|desafio-totp"))
	return h[:]
}

// emitirDesafio firma el desafío para el usuario que ya superó la contraseña.
func (s *Service) emitirDesafio(u *user.Usuario, dispositivoID string) (*DesafioTOTP, error) {
	now := s.clock.Now()
	proposito := DesafioConfigurar
	if u.TOTPActivado {
		proposito = DesafioVerificar
	}
	expira := now.Add(vigenciaDesafio)
	claims := desafioClaims{
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    s.cfg.JWTIssuer,
			Subject:   u.ID,
			ExpiresAt: jwt.NewNumericDate(expira),
			IssuedAt:  jwt.NewNumericDate(now),
			ID:        shared.NewID(),
		},
		UsuarioID:     u.ID,
		Proposito:     proposito,
		DispositivoID: dispositivoID,
	}
	firmado, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(s.claveDesafio())
	if err != nil {
		return nil, err
	}
	return &DesafioTOTP{Token: firmado, Proposito: proposito, ExpiraEn: expira}, nil
}

// leerDesafio valida firma, vigencia y propósito, y devuelve el usuario vigente con el
// dispositivo que inició el login.
func (s *Service) leerDesafio(ctx context.Context, token, proposito string) (*user.Usuario, string, error) {
	invalido := shared.NewAuthError(shared.ErrTokenExpirado,
		"El desafío de segundo factor expiró o no es válido; inicia sesión de nuevo")
	claims := &desafioClaims{}
	parsed, err := jwt.ParseWithClaims(token, claims, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("algoritmo inesperado")
		}
		return s.claveDesafio(), nil
	}, jwt.WithTimeFunc(s.clock.Now))
	if err != nil || !parsed.Valid || claims.Proposito != proposito {
		return nil, "", invalido
	}
	u, err := s.usuarios.FindByID(ctx, claims.UsuarioID)
	if err != nil || u == nil || !u.Activo || u.Eliminado {
		return nil, "", invalido
	}
	if u.BloqueadoHasta != nil && s.clock.Now().Before(*u.BloqueadoHasta) {
		return nil, "", shared.NewAuthError(shared.ErrCuentaBloqueada,
			"Cuenta bloqueada. Inténtalo de nuevo a las "+shared.HoraLocal(*u.BloqueadoHasta))
	}
	return u, claims.DispositivoID, nil
}
