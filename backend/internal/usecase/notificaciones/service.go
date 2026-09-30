// Package notificaciones — registro de tokens, preferencias y bandeja del usuario (EP-10:
// US-NOT-01 AC-01, US-NOT-02 AC-02).
package notificaciones

import (
	"context"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// Service atiende las rutas /me/notificaciones.
type Service struct {
	tokens         repository.TokenPushRepository
	preferencias   repository.PreferenciasRepository
	notificaciones repository.NotificacionRepository
}

// NewService crea el servicio de notificaciones del usuario.
func NewService(t repository.TokenPushRepository, p repository.PreferenciasRepository, n repository.NotificacionRepository) *Service {
	return &Service{tokens: t, preferencias: p, notificaciones: n}
}

var plataformasValidas = map[string]bool{"ANDROID": true, "IOS": true, "WEB": true}

// RegistrarToken asocia el token FCM al usuario y a la instalación que lo envía.
func (s *Service) RegistrarToken(ctx context.Context, usuarioID, token, plataforma, dispositivoID string) error {
	token, plataforma = strings.TrimSpace(token), strings.ToUpper(strings.TrimSpace(plataforma))
	if token == "" || len(token) > 4096 || !plataformasValidas[plataforma] {
		return shared.NewValidationError("Token o plataforma inválidos",
			shared.FieldError{Campo: "token", Error: "REQUERIDO"},
			shared.FieldError{Campo: "plataforma", Error: "ANDROID, IOS o WEB"})
	}
	return s.tokens.Guardar(ctx, repository.TokenPush{
		Token: token, UsuarioID: usuarioID, DispositivoID: dispositivoID, Plataforma: plataforma, ActualizadoEn: time.Now().UTC(),
	})
}

// EliminarToken borra el token al cerrar sesión; solo el dueño puede borrarlo (US-NOT-01 AC-04).
func (s *Service) EliminarToken(ctx context.Context, usuarioID, token string) error {
	propios, err := s.tokens.ListarPorUsuario(ctx, usuarioID)
	if err != nil {
		return err
	}
	for _, t := range propios {
		if t.Token == token {
			return s.tokens.Eliminar(ctx, token)
		}
	}
	return nil
}

// RespuestaPreferencias añade las obligatorias para que la app las muestre bloqueadas.
type RespuestaPreferencias struct {
	notificacion.Preferencias
	Obligatorias []string `json:"obligatorias"`
}

// Preferencias devuelve las del usuario o las predeterminadas.
func (s *Service) Preferencias(ctx context.Context, usuarioID string) (RespuestaPreferencias, error) {
	p, err := s.preferencias.Obtener(ctx, usuarioID)
	if err != nil {
		return RespuestaPreferencias{}, err
	}
	pref := notificacion.PreferenciasPorDefecto()
	if p != nil {
		pref = *p
	}
	pref.AplicarObligatorias()
	return RespuestaPreferencias{Preferencias: pref, Obligatorias: notificacion.Obligatorias}, nil
}

// GuardarPreferencias guarda la elección sin permitir desactivar las obligatorias.
func (s *Service) GuardarPreferencias(ctx context.Context, usuarioID string, p notificacion.Preferencias) (RespuestaPreferencias, error) {
	p.AplicarObligatorias()
	if err := s.preferencias.Guardar(ctx, usuarioID, p); err != nil {
		return RespuestaPreferencias{}, err
	}
	return RespuestaPreferencias{Preferencias: p, Obligatorias: notificacion.Obligatorias}, nil
}

// ItemBandeja es un aviso tal como lo muestra la app.
type ItemBandeja struct {
	ID       string            `json:"id"`
	Tipo     notificacion.Tipo `json:"tipo"`
	Titulo   string            `json:"titulo"`
	Cuerpo   string            `json:"cuerpo"`
	Datos    map[string]string `json:"datos"`
	CreadaEn time.Time         `json:"creadaEn"`
	Leida    bool              `json:"leida"`
}

// Bandeja lista los avisos del usuario, recientes primero (máximo 100).
func (s *Service) Bandeja(ctx context.Context, usuarioID string, limite int) ([]ItemBandeja, error) {
	if limite <= 0 || limite > 100 {
		limite = 30
	}
	ns, err := s.notificaciones.Bandeja(ctx, usuarioID, limite)
	if err != nil {
		return nil, err
	}
	items := make([]ItemBandeja, len(ns))
	for i, n := range ns {
		items[i] = ItemBandeja{ID: n.ID, Tipo: n.Tipo, Titulo: n.Titulo, Cuerpo: n.Cuerpo, Datos: n.Datos, CreadaEn: n.CreadaEn, Leida: n.Leida}
	}
	return items, nil
}

// MarcarLeida marca un aviso propio como leído.
func (s *Service) MarcarLeida(ctx context.Context, usuarioID, id string) error {
	ok, err := s.notificaciones.MarcarLeida(ctx, id, usuarioID)
	if err != nil {
		return err
	}
	if !ok {
		return shared.NewNotFoundError("notificación", id)
	}
	return nil
}
