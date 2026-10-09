package privacidad

import (
	"context"
	"time"

	"github.com/siaa/backend/internal/domain/justificacion"
	"github.com/siaa/backend/internal/domain/marcaje"
	domain "github.com/siaa/backend/internal/domain/privacidad"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// maxRegistrosCopia acota cada colección de la copia (una carrera docente cabe holgada).
const maxRegistrosCopia = 20000

// DatosPersonalesCopia son los datos de identificación de la cuenta, sin credenciales.
type DatosPersonalesCopia struct {
	ID           string       `json:"id"`
	Correo       string       `json:"correo"`
	Nombre       string       `json:"nombre"`
	Apellido     string       `json:"apellido"`
	Documento    string       `json:"documento,omitempty"`
	Activo       bool         `json:"activo"`
	Roles        []RolCopia   `json:"roles"`
	Ambitos      []rbac.Scope `json:"ambitos"`
	TOTPActivado bool         `json:"verificacionDosPasosActivada"`
	CreadoEn     time.Time    `json:"creadoEn"`
}

// RolCopia es un rol asignado con su vigencia.
type RolCopia struct {
	Nombre         string     `json:"nombre"`
	VigenciaInicio *time.Time `json:"vigenciaInicio,omitempty"`
	VigenciaFin    *time.Time `json:"vigenciaFin,omitempty"`
}

// DispositivoCopia describe un dispositivo vinculado.
type DispositivoCopia struct {
	InstalacionID string     `json:"instalacionId"`
	Modelo        string     `json:"modelo"`
	SO            string     `json:"so"`
	VersionApp    string     `json:"versionApp"`
	Confiable     bool       `json:"confiable"`
	CreadoEn      time.Time  `json:"creadoEn"`
	RevocadoEn    *time.Time `json:"revocadoEn,omitempty"`
}

// ConsentimientoCopia es una decisión sobre el aviso de privacidad.
type ConsentimientoCopia struct {
	Version       string    `json:"version"`
	Decision      string    `json:"decision"`
	DispositivoID string    `json:"dispositivoId,omitempty"`
	DecididoEn    time.Time `json:"decididoEn"`
}

// CopiaDatos es el archivo estructurado que recibe el titular (US-LEG-02 AC-01).
type CopiaDatos struct {
	GeneradaEn      time.Time                      `json:"generadaEn"`
	Responsable     string                         `json:"responsable"`
	Titular         DatosPersonalesCopia           `json:"titular"`
	Dispositivos    []DispositivoCopia             `json:"dispositivos"`
	Marcajes        []*marcaje.Marcaje             `json:"marcajes"`
	Justificaciones []*justificacion.Justificacion `json:"justificaciones"`
	Consentimientos []ConsentimientoCopia          `json:"consentimientos"`
	Solicitudes     []*domain.SolicitudDerecho     `json:"solicitudesDerechos"`
}

// ExportarDatos arma la copia completa de los datos personales del titular y la audita. Se
// entrega en el acto, dentro del plazo legal de consulta (10 días hábiles).
func (s *DerechosService) ExportarDatos(ctx context.Context, titularID, ip string) (*CopiaDatos, error) {
	u, err := s.usuarios.FindByID(ctx, titularID)
	if err != nil {
		return nil, err
	}
	if u == nil {
		return nil, shared.NewNotFoundError("Usuario", titularID)
	}
	copia := &CopiaDatos{
		GeneradaEn: s.ahora(), Responsable: s.canal.Institucion,
		Titular: DatosPersonalesCopia{
			ID: u.ID, Correo: u.Correo, Nombre: u.Nombre, Apellido: u.Apellido, Documento: u.Documento,
			Activo: u.Activo, Ambitos: append([]rbac.Scope{}, u.Ambitos...), TOTPActivado: u.TOTPActivado, CreadoEn: u.CreadoEn,
		},
		Dispositivos: []DispositivoCopia{}, Marcajes: []*marcaje.Marcaje{},
		Justificaciones: []*justificacion.Justificacion{}, Consentimientos: []ConsentimientoCopia{},
	}
	for _, r := range u.Roles {
		copia.Titular.Roles = append(copia.Titular.Roles, RolCopia{Nombre: string(r.Nombre), VigenciaInicio: r.VigenciaInicio, VigenciaFin: r.VigenciaFin})
	}
	if err := s.completarCopia(ctx, titularID, copia); err != nil {
		return nil, err
	}
	s.auditar(ctx, titularID, "", ip, "DATOS_PERSONALES_EXPORTADOS", titularID, nil, map[string]int{
		"marcajes": len(copia.Marcajes), "justificaciones": len(copia.Justificaciones),
		"consentimientos": len(copia.Consentimientos), "dispositivos": len(copia.Dispositivos),
	})
	return copia, nil
}

// completarCopia agrega los registros de cada fuente configurada.
func (s *DerechosService) completarCopia(ctx context.Context, titularID string, copia *CopiaDatos) error {
	f := s.fuentes
	if f.Dispositivos != nil {
		lista, err := f.Dispositivos.FindByUsuario(ctx, titularID)
		if err != nil {
			return err
		}
		for _, d := range lista {
			copia.Dispositivos = append(copia.Dispositivos, DispositivoCopia{InstalacionID: d.InstalacionID, Modelo: d.Modelo,
				SO: d.SO, VersionApp: d.VersionApp, Confiable: d.Confiable, CreadoEn: d.CreadoEn, RevocadoEn: d.RevocadoEn})
		}
	}
	if f.Marcajes != nil {
		lista, _, err := f.Marcajes.ListarPorUsuario(ctx, titularID, "", 0, maxRegistrosCopia)
		if err != nil {
			return err
		}
		copia.Marcajes = append(copia.Marcajes, lista...)
	}
	if f.Justificaciones != nil {
		lista, _, err := f.Justificaciones.Listar(ctx, repository.FiltroJustificaciones{DocenteID: titularID}, 0, maxRegistrosCopia)
		if err != nil {
			return err
		}
		copia.Justificaciones = append(copia.Justificaciones, lista...)
	}
	if f.Consentimientos != nil {
		lista, err := f.Consentimientos.Historial(ctx, titularID)
		if err != nil {
			return err
		}
		for _, c := range lista {
			copia.Consentimientos = append(copia.Consentimientos, ConsentimientoCopia{Version: c.Version,
				Decision: string(c.Decision), DispositivoID: c.DispositivoID, DecididoEn: c.DecididoEn})
		}
	}
	sols, err := s.MisSolicitudes(ctx, titularID)
	if err != nil {
		return err
	}
	copia.Solicitudes = sols
	return nil
}
