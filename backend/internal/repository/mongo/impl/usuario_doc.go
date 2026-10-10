// Package impl — documento BSON de usuarios y su conversión al dominio.
package impl

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/user"
)

// ─── Documento BSON ──────────────────────────────────────────

type usuarioDoc struct {
	ID                   primitive.ObjectID `bson:"_id,omitempty"`
	Correo               string             `bson:"correo"`
	PasswordHash         string             `bson:"passwordHash"`
	Nombre               string             `bson:"nombre"`
	Apellido             string             `bson:"apellido"`
	Documento            string             `bson:"documento,omitempty"`
	Activo               bool               `bson:"activo"`
	Eliminado            bool               `bson:"eliminado"`
	Roles                []rolAsignadoDoc   `bson:"roles"`
	Ambitos              []ambitoDoc        `bson:"ambitos"`
	IntentosFallidos     int                `bson:"intentosFallidos"`
	BloqueadoHasta       *time.Time         `bson:"bloqueadoHasta,omitempty"`
	UltimoFalloEn        *time.Time         `bson:"ultimoFalloEn,omitempty"`
	DispositivoVinculado *string            `bson:"dispositivoVinculado,omitempty"`
	// Estado de seguridad: sin estos campos un Update (ReplaceOne) borraba el 2FA y la
	// revocación remota de sesiones.
	SesionesRevocadasAntes *time.Time `bson:"sesionesRevocadasAntes,omitempty"`
	TOTPSecreto            string     `bson:"totpSecreto,omitempty"`
	TOTPActivado           bool       `bson:"totpActivado"`
	BackupCodes            []string   `bson:"backupCodes,omitempty"`
	IntentosFallidosTOTP   int        `bson:"intentosFallidosTotp"`
	BloqueadoHastaTOTP     *time.Time `bson:"bloqueadoHastaTotp,omitempty"`
	CreadoEn               time.Time  `bson:"creadoEn"`
	ActualizadoEn          time.Time  `bson:"actualizadoEn"`
}

type rolAsignadoDoc struct {
	RolID          string     `bson:"rolId"`
	Nombre         string     `bson:"nombre"`
	VigenciaInicio *time.Time `bson:"vigenciaInicio,omitempty"`
	VigenciaFin    *time.Time `bson:"vigenciaFin,omitempty"`
	AsignadoPor    string     `bson:"asignadoPor,omitempty"`
}

type ambitoDoc struct {
	Tipo string `bson:"tipo"`
	ID   string `bson:"id"`
}

// ─── Conversores BSON ↔ dominio ──────────────────────────────

func docToUsuario(d *usuarioDoc) *user.Usuario {
	u := &user.Usuario{
		ID:                   d.ID.Hex(),
		Correo:               d.Correo,
		PasswordHash:         d.PasswordHash,
		Nombre:               d.Nombre,
		Apellido:             d.Apellido,
		Documento:            d.Documento,
		Activo:               d.Activo,
		Eliminado:            d.Eliminado,
		IntentosFallidos:     d.IntentosFallidos,
		BloqueadoHasta:       d.BloqueadoHasta,
		UltimoFalloEn:        d.UltimoFalloEn,
		DispositivoVinculado: d.DispositivoVinculado,
		CreadoEn:             d.CreadoEn,
		ActualizadoEn:        d.ActualizadoEn,

		SesionesRevocadasAntes: d.SesionesRevocadasAntes,
		TOTPSecreto:            d.TOTPSecreto,
		TOTPActivado:           d.TOTPActivado,
		BackupCodes:            d.BackupCodes,
		IntentosFallidosTOTP:   d.IntentosFallidosTOTP,
		BloqueadoHastaTOTP:     d.BloqueadoHastaTOTP,
	}
	for _, r := range d.Roles {
		u.Roles = append(u.Roles, user.RolAsignado{
			RolID:          r.RolID,
			Nombre:         rbac.RoleName(r.Nombre),
			VigenciaInicio: r.VigenciaInicio,
			VigenciaFin:    r.VigenciaFin,
			AsignadoPor:    r.AsignadoPor,
		})
	}
	for _, a := range d.Ambitos {
		u.Ambitos = append(u.Ambitos, rbac.Scope{
			Tipo: rbac.ScopeType(a.Tipo),
			ID:   a.ID,
		})
	}
	return u
}

func usuarioToDoc(u *user.Usuario) *usuarioDoc {
	d := &usuarioDoc{
		Correo:               u.Correo,
		PasswordHash:         u.PasswordHash,
		Nombre:               u.Nombre,
		Apellido:             u.Apellido,
		Documento:            u.Documento,
		Activo:               u.Activo,
		Eliminado:            u.Eliminado,
		IntentosFallidos:     u.IntentosFallidos,
		BloqueadoHasta:       u.BloqueadoHasta,
		UltimoFalloEn:        u.UltimoFalloEn,
		DispositivoVinculado: u.DispositivoVinculado,
		CreadoEn:             u.CreadoEn,
		ActualizadoEn:        u.ActualizadoEn,

		SesionesRevocadasAntes: u.SesionesRevocadasAntes,
		TOTPSecreto:            u.TOTPSecreto,
		TOTPActivado:           u.TOTPActivado,
		BackupCodes:            u.BackupCodes,
		IntentosFallidosTOTP:   u.IntentosFallidosTOTP,
		BloqueadoHastaTOTP:     u.BloqueadoHastaTOTP,
	}
	if u.ID != "" {
		if oid, err := primitive.ObjectIDFromHex(u.ID); err == nil {
			d.ID = oid
		}
	}
	for _, r := range u.Roles {
		d.Roles = append(d.Roles, rolAsignadoDoc{
			RolID:          r.RolID,
			Nombre:         string(r.Nombre),
			VigenciaInicio: r.VigenciaInicio,
			VigenciaFin:    r.VigenciaFin,
			AsignadoPor:    r.AsignadoPor,
		})
	}
	for _, a := range u.Ambitos {
		d.Ambitos = append(d.Ambitos, ambitoDoc{
			Tipo: string(a.Tipo),
			ID:   a.ID,
		})
	}
	return d
}
