package privacidad

import (
	"context"
	"errors"
	"fmt"
	"strings"

	domain "github.com/siaa/backend/internal/domain/privacidad"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/domain/user"
	"github.com/siaa/backend/internal/repository"
)

// ActorDerechos es quien atiende el caso desde la consola.
type ActorDerechos struct {
	UsuarioID string
	RolActivo string
	IPOrigen  string
}

// obtener carga el caso o devuelve 404.
func (s *DerechosService) obtener(ctx context.Context, id string) (*domain.SolicitudDerecho, error) {
	sol, err := s.solicitudes.Obtener(ctx, id)
	if err != nil {
		return nil, err
	}
	if sol == nil {
		return nil, shared.NewNotFoundError("Solicitud", id)
	}
	return sol, nil
}

// Asumir deja el caso a cargo de quien lo atiende y lo pone en trámite (AC-02).
func (s *DerechosService) Asumir(ctx context.Context, actor ActorDerechos, id string) (*domain.SolicitudDerecho, error) {
	sol, err := s.obtener(ctx, id)
	if err != nil {
		return nil, err
	}
	if sol.TitularID == actor.UsuarioID {
		return nil, &shared.DomainError{Code: shared.ErrPermisosDenegados, Message: "No puede atender su propia solicitud"}
	}
	previo, antes := sol.Estado, copiaSolicitud(sol)
	if err := sol.Asignar(actor.UsuarioID, actor.UsuarioID, s.ahora()); err != nil {
		return nil, err
	}
	if err := s.guardar(ctx, sol, previo); err != nil {
		return nil, err
	}
	s.auditar(ctx, actor.UsuarioID, actor.RolActivo, actor.IPOrigen, "SOLICITUD_DERECHOS_ASIGNADA", sol.ID, antes, sol)
	return sol, nil
}

// Resolver responde el caso. Si se atiende, la rectificación se aplica a la cuenta y la
// supresión elimina lo eliminable (ubicaciones y avisos); lo demás se conserva según la
// evaluación. Todo queda auditado (AC-02, AC-03).
func (s *DerechosService) Resolver(ctx context.Context, actor ActorDerechos, id string, atendida bool, respuesta string) (*domain.SolicitudDerecho, error) {
	sol, err := s.obtener(ctx, id)
	if err != nil {
		return nil, err
	}
	if sol.TitularID == actor.UsuarioID {
		return nil, &shared.DomainError{Code: shared.ErrPermisosDenegados, Message: "No puede resolver su propia solicitud"}
	}
	previo, antes := sol.Estado, copiaSolicitud(sol)
	if err := sol.Resolver(actor.UsuarioID, atendida, respuesta, s.ahora()); err != nil {
		return nil, err
	}
	if atendida {
		if err := s.aplicar(ctx, actor, sol); err != nil {
			return nil, err
		}
	}
	if err := s.guardar(ctx, sol, previo); err != nil {
		return nil, err
	}
	s.auditar(ctx, actor.UsuarioID, actor.RolActivo, actor.IPOrigen, "SOLICITUD_DERECHOS_"+string(sol.Estado), sol.ID, antes, sol)
	if s.avisos != nil {
		s.avisos.SolicitudDerechosResuelta(ctx, sol.TitularID, sol.ID, strings.ToLower(string(sol.Tipo)), strings.ToLower(string(sol.Estado)))
	}
	return sol, nil
}

func (s *DerechosService) guardar(ctx context.Context, sol *domain.SolicitudDerecho, previo domain.EstadoSolicitud) error {
	if err := s.solicitudes.Actualizar(ctx, sol, previo); err != nil {
		if errors.Is(err, repository.ErrSolicitudModificada) {
			return &shared.DomainError{Code: shared.ErrConflictoUnicidad, Message: "Otra persona ya atendió esta solicitud"}
		}
		return err
	}
	return nil
}

// aplicar ejecuta lo que la solicitud atendida pide sobre los datos.
func (s *DerechosService) aplicar(ctx context.Context, actor ActorDerechos, sol *domain.SolicitudDerecho) error {
	switch sol.Tipo {
	case domain.SolicitudRectificacion:
		return s.rectificar(ctx, actor, sol)
	case domain.SolicitudSupresion:
		return s.suprimir(ctx, actor, sol)
	}
	return nil
}

// rectificar corrige nombre, apellido o documento de la cuenta del titular.
func (s *DerechosService) rectificar(ctx context.Context, actor ActorDerechos, sol *domain.SolicitudDerecho) error {
	u, err := s.usuarios.FindByID(ctx, sol.TitularID)
	if err != nil || u == nil {
		return fmt.Errorf("titular no encontrado: %w", err)
	}
	antes := datosRectificables(u)
	if doc := sol.Cambios["documento"]; doc != "" && doc != u.Documento {
		if otro, err := s.usuarios.FindByDocumento(ctx, doc); err == nil && otro != nil && otro.ID != u.ID {
			return &shared.DomainError{Code: shared.ErrConflictoUnicidad, Message: "Ese documento ya pertenece a otra cuenta"}
		}
		u.Documento = doc
	}
	if v := sol.Cambios["nombre"]; v != "" {
		u.Nombre = v
	}
	if v := sol.Cambios["apellido"]; v != "" {
		u.Apellido = v
	}
	u.ActualizadoEn = s.ahora()
	if err := s.usuarios.Update(ctx, u); err != nil {
		return err
	}
	s.auditarUsuario(ctx, actor, u.ID, "DATOS_RECTIFICADOS", antes, datosRectificables(u))
	return nil
}

// suprimir elimina las categorías marcadas como eliminables en la evaluación vigente.
func (s *DerechosService) suprimir(ctx context.Context, actor ActorDerechos, sol *domain.SolicitudDerecho) error {
	if s.supresion == nil {
		return nil
	}
	sol.Evaluacion = domain.EvaluarSupresion(s.bajoInvestigacion(ctx, sol.TitularID))
	resumen := map[string]interface{}{}
	for _, e := range sol.Evaluacion {
		if e.Decision != domain.SeElimina {
			continue
		}
		switch e.Categoria {
		case domain.CategoriaUbicaciones:
			n, err := s.supresion.AnonimizarUbicacionesDe(ctx, sol.TitularID, s.exclusionActiva(ctx))
			if err != nil {
				return err
			}
			resumen["ubicacionesAnonimizadas"] = n
		case domain.CategoriaAvisos:
			if err := s.supresion.EliminarAvisosDe(ctx, sol.TitularID); err != nil {
				return err
			}
			resumen["avisosEliminados"] = true
		}
	}
	s.auditarUsuario(ctx, actor, sol.TitularID, "DATOS_SUPRIMIDOS", nil, resumen)
	return nil
}

// exclusionActiva reúne los registros protegidos por investigaciones en curso.
func (s *DerechosService) exclusionActiva(ctx context.Context) domain.ExclusionRetencion {
	if s.investigaciones == nil {
		return domain.ExclusionRetencion{}
	}
	activas, _ := s.investigaciones.Activas(ctx)
	return domain.ExclusionDe(activas...)
}

func (s *DerechosService) auditarUsuario(ctx context.Context, actor ActorDerechos, usuarioID, accion string, antes, despues interface{}) {
	if s.auditoria == nil {
		return
	}
	_ = s.auditoria.Create(ctx, &repository.AuditEntry{
		Entidad: "usuarios", EntidadID: usuarioID, Accion: accion, ActorID: actor.UsuarioID, RolActivo: actor.RolActivo,
		IPOrigen: actor.IPOrigen, ValorAnterior: antes, ValorNuevo: despues, CreadoEn: s.ahora(),
	})
}

func datosRectificables(u *user.Usuario) map[string]string {
	return map[string]string{"nombre": u.Nombre, "apellido": u.Apellido, "documento": u.Documento}
}

// copiaSolicitud toma una instantánea del caso para la auditoría (antes del cambio).
func copiaSolicitud(s *domain.SolicitudDerecho) *domain.SolicitudDerecho {
	c := *s
	c.Historial = append([]domain.TransicionSolicitud(nil), s.Historial...)
	return &c
}
