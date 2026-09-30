package usuarios

import (
	"context"
	"time"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// Perfil es lo que el propio usuario ve de su cuenta en la app (§9.1 "Perfil").
type Perfil struct {
	ID           string              `json:"id"`
	Nombre       string              `json:"nombre"`
	Apellido     string              `json:"apellido"`
	Correo       string              `json:"correo"`
	Documento    string              `json:"documento,omitempty"`
	Roles        []string            `json:"roles"`
	TOTPActivado bool                `json:"totpActivado"`
	Dispositivos []DispositivoPerfil `json:"dispositivos"`
}

// DispositivoPerfil es un dispositivo vinculado a la cuenta (RF-AUT-004).
type DispositivoPerfil struct {
	InstalacionID       string     `json:"instalacionId"`
	Modelo              string     `json:"modelo"`
	SO                  string     `json:"so"`
	VersionApp          string     `json:"versionApp"`
	Confiable           bool       `json:"confiable"`
	PendienteAprobacion bool       `json:"pendienteAprobacion"`
	VinculadoEn         time.Time  `json:"vinculadoEn"`
	RevocadoEn          *time.Time `json:"revocadoEn,omitempty"`
}

// ServicioPerfil arma el perfil propio sin exigir permisos de administración de usuarios.
type ServicioPerfil struct {
	usuarios     repository.UsuarioRepository
	dispositivos repository.DispositivoRepository
}

// NewServicioPerfil crea el servicio; dispositivos puede ser nil.
func NewServicioPerfil(u repository.UsuarioRepository, d repository.DispositivoRepository) *ServicioPerfil {
	return &ServicioPerfil{usuarios: u, dispositivos: d}
}

// Obtener devuelve el perfil del usuario autenticado.
func (s *ServicioPerfil) Obtener(ctx context.Context, usuarioID string) (*Perfil, error) {
	u, err := s.usuarios.FindByID(ctx, usuarioID)
	if err != nil {
		return nil, err
	}
	if u == nil || u.Eliminado {
		return nil, shared.NewNotFoundError("usuario", usuarioID)
	}
	p := &Perfil{ID: u.ID, Nombre: u.Nombre, Apellido: u.Apellido, Correo: u.Correo, Documento: u.Documento,
		TOTPActivado: u.TOTPActivado, Roles: []string{}, Dispositivos: []DispositivoPerfil{}}
	for _, r := range u.Roles {
		p.Roles = append(p.Roles, string(r.Nombre))
	}
	if s.dispositivos == nil {
		return p, nil
	}
	ds, err := s.dispositivos.FindByUsuario(ctx, usuarioID)
	if err != nil {
		return nil, err
	}
	for _, d := range ds {
		p.Dispositivos = append(p.Dispositivos, DispositivoPerfil{
			InstalacionID: d.InstalacionID, Modelo: d.Modelo, SO: d.SO, VersionApp: d.VersionApp,
			Confiable: d.Confiable, PendienteAprobacion: d.PendienteAprobacion,
			VinculadoEn: d.CreadoEn, RevocadoEn: d.RevocadoEn,
		})
	}
	return p, nil
}
