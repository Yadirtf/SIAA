// Package privacidad — ejercicio de los derechos del titular (US-LEG-02, RNF-LEG-004):
//
//   - derechos.go          → servicio, radicación y consultas (este archivo)
//   - derechos_resolver.go → asignación del responsable, resolución y su aplicación
//   - copia_datos.go       → copia estructurada de los datos personales (AC-01)
package privacidad

import (
	"context"
	"fmt"
	"time"

	domain "github.com/siaa/backend/internal/domain/privacidad"
	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

// AvisoDerechos encola los avisos del caso (lo implementa el productor de notificaciones).
type AvisoDerechos interface {
	SolicitudDerechosRadicada(ctx context.Context, responsableID, solicitudID, tipo string, vence time.Time)
	SolicitudDerechosResuelta(ctx context.Context, titularID, solicitudID, tipo, estado string)
}

// FuentesCopia reúne los repositorios de los que sale la copia de datos del titular.
type FuentesCopia struct {
	Dispositivos    repository.DispositivoRepository
	Marcajes        repository.MarcajeRepository
	Justificaciones repository.JustificacionRepository
	Consentimientos repository.ConsentimientoHistorialRepository
}

// DerechosService atiende las solicitudes de copia, rectificación y supresión del titular.
type DerechosService struct {
	canal           domain.CanalDerechos
	solicitudes     repository.SolicitudDerechoRepository
	usuarios        repository.UsuarioRepository
	investigaciones repository.InvestigacionRepository
	supresion       repository.SupresionTitularRepository
	auditoria       repository.AuditoriaRepository
	fuentes         FuentesCopia
	avisos          AvisoDerechos
	ahora           func() time.Time
}

// NewDerechosService crea el servicio; investigaciones, fuentes y avisos son opcionales.
func NewDerechosService(canal domain.CanalDerechos, solicitudes repository.SolicitudDerechoRepository,
	usuarios repository.UsuarioRepository, supresion repository.SupresionTitularRepository, auditoria repository.AuditoriaRepository,
) *DerechosService {
	return &DerechosService{canal: canal, solicitudes: solicitudes, usuarios: usuarios, supresion: supresion,
		auditoria: auditoria, ahora: func() time.Time { return time.Now().UTC() }}
}

// WithInvestigaciones protege las ubicaciones bajo investigación en curso (US-AUD-04).
func (s *DerechosService) WithInvestigaciones(r repository.InvestigacionRepository) *DerechosService {
	s.investigaciones = r
	return s
}

// WithFuentes habilita la copia de marcajes, justificaciones, dispositivos y consentimientos.
func (s *DerechosService) WithFuentes(f FuentesCopia) *DerechosService {
	s.fuentes = f
	return s
}

// WithAvisos habilita los avisos al responsable y al titular.
func (s *DerechosService) WithAvisos(a AvisoDerechos) *DerechosService {
	s.avisos = a
	return s
}

// Canal devuelve el canal de derechos publicado con sus plazos legales (AC-04).
func (s *DerechosService) Canal() domain.CanalDerechos { return s.canal }

// SolicitudRadicacion es lo que envía el titular.
type SolicitudRadicacion struct {
	TitularID   string
	Tipo        domain.TipoSolicitud
	Descripcion string
	Cambios     map[string]string
	IPOrigen    string
}

// Radicar crea el caso con su plazo legal y su responsable (AC-02). Una supresión trae la
// evaluación de qué se elimina y qué se conserva, con fundamento (AC-03).
func (s *DerechosService) Radicar(ctx context.Context, req SolicitudRadicacion) (*domain.SolicitudDerecho, error) {
	sol, err := domain.NuevaSolicitud(req.TitularID, req.Tipo, req.Descripcion, req.Cambios, s.ahora())
	if err != nil {
		return nil, err
	}
	abiertas, err := s.solicitudes.Listar(ctx, repository.FiltroSolicitudesDerechos{TitularID: req.TitularID, Tipo: req.Tipo, SoloAbiertas: true}, 1)
	if err != nil {
		return nil, err
	}
	if len(abiertas) > 0 {
		return nil, &shared.DomainError{Code: shared.ErrConflictoUnicidad,
			Message: fmt.Sprintf("Ya tiene una solicitud de %s en trámite; espere su respuesta", req.Tipo)}
	}
	if sol.Tipo == domain.SolicitudSupresion {
		sol.Evaluacion = domain.EvaluarSupresion(s.bajoInvestigacion(ctx, req.TitularID))
	}
	sol.ResponsableID = s.responsablePorDefecto(ctx, req.TitularID)
	if err := s.solicitudes.Crear(ctx, sol); err != nil {
		return nil, err
	}
	s.auditar(ctx, req.TitularID, "", req.IPOrigen, "SOLICITUD_DERECHOS_RADICADA", sol.ID, nil, sol)
	if s.avisos != nil && sol.ResponsableID != "" {
		s.avisos.SolicitudDerechosRadicada(ctx, sol.ResponsableID, sol.ID, string(sol.Tipo), sol.VenceEn)
	}
	return sol, nil
}

// EvaluarSupresion informa, antes de radicar, qué datos pueden eliminarse (AC-03).
func (s *DerechosService) EvaluarSupresion(ctx context.Context, titularID string) []domain.ElementoSupresion {
	return domain.EvaluarSupresion(s.bajoInvestigacion(ctx, titularID))
}

// MisSolicitudes lista los casos del titular.
func (s *DerechosService) MisSolicitudes(ctx context.Context, titularID string) ([]*domain.SolicitudDerecho, error) {
	return s.solicitudes.Listar(ctx, repository.FiltroSolicitudesDerechos{TitularID: titularID}, 100)
}

// bajoInvestigacion indica si una investigación en curso recae sobre el titular.
func (s *DerechosService) bajoInvestigacion(ctx context.Context, titularID string) bool {
	if s.investigaciones == nil {
		return false
	}
	activas, err := s.investigaciones.Activas(ctx)
	if err != nil {
		return true // ante la duda se conserva la prueba
	}
	for _, id := range domain.ExclusionDe(activas...).UsuarioIDs {
		if id == titularID {
			return true
		}
	}
	return false
}

// responsablePorDefecto asigna el caso a la administración institucional (o, sin ella, a un
// superadministrador), nunca al propio titular.
func (s *DerechosService) responsablePorDefecto(ctx context.Context, titularID string) string {
	activo := true
	for _, rol := range []rbac.RoleName{rbac.RolAdminInst, rbac.RolSuperadmin} {
		lista, _, err := s.usuarios.Buscar(ctx, repository.FiltroUsuarios{Rol: string(rol), Activo: &activo, Limite: 10})
		if err != nil {
			continue
		}
		for _, u := range lista {
			if u.ID != titularID {
				return u.ID
			}
		}
	}
	return ""
}

func (s *DerechosService) auditar(ctx context.Context, actorID, rol, ip, accion, id string, antes, despues interface{}) {
	if s.auditoria == nil {
		return
	}
	_ = s.auditoria.Create(ctx, &repository.AuditEntry{
		Entidad: "solicitudes_derechos", EntidadID: id, Accion: accion, ActorID: actorID, RolActivo: rol,
		IPOrigen: ip, ValorAnterior: antes, ValorNuevo: despues, CreadoEn: s.ahora(),
	})
}
