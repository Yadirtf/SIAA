package academico

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/shared"
	applog "github.com/siaa/backend/internal/platform/log"
	"github.com/siaa/backend/internal/repository"
)

// TipoTrabajoGeneracion identifica los trabajos de generación de sesiones.
const TipoTrabajoGeneracion = "GENERACION_SESIONES"

// limiteGeneracion acota la duración de una generación en segundo plano.
const limiteGeneracion = 10 * time.Minute

// ErrTrabajosNoDisponibles indica que el despliegue no tiene el repositorio de trabajos.
var ErrTrabajosNoDisponibles = errors.New("la ejecución asíncrona no está disponible")

// WithTrabajos habilita la generación asíncrona consultable.
func (s *Service) WithTrabajos(repo repository.TrabajoRepository) *Service {
	s.trabajoRepo = repo
	return s
}

// IniciarGeneracion valida el periodo y lanza la generación en segundo plano; devuelve el
// trabajo para consultar su estado e informe (US-ACA-05 AC-04: no bloquea la API).
func (s *Service) IniciarGeneracion(ctx context.Context, cmd GenerarSesionesCmd) (*repository.Trabajo, error) {
	if s.trabajoRepo == nil {
		return nil, ErrTrabajosNoDisponibles
	}
	periodo, err := s.periodoRepo.GetByID(ctx, cmd.PeriodoID)
	if err != nil || periodo == nil {
		return nil, shared.NewNotFoundError("Periodo", cmd.PeriodoID)
	}
	if periodo.Estado() == academico.EstadoCerrado {
		return nil, academico.ErrPeriodoCerradoModif
	}
	t := &repository.Trabajo{ID: shared.NewID(), Tipo: TipoTrabajoGeneracion, Estado: repository.TrabajoEnProceso,
		CreadoPor: cmd.Actor.UsuarioID, CreadoEn: s.clk.Now()}
	if err := s.trabajoRepo.Crear(ctx, t); err != nil {
		return nil, err
	}
	copia := *t
	go s.ejecutarGeneracion(copia, cmd)
	return t, nil
}

func (s *Service) ejecutarGeneracion(t repository.Trabajo, cmd GenerarSesionesCmd) {
	ctx, cancelar := context.WithTimeout(context.Background(), limiteGeneracion)
	defer cancelar()
	informe, err := s.GenerarSesiones(ctx, cmd)
	fin := s.clk.Now()
	t.FinalizadoEn = &fin
	t.Progreso = 100
	if err != nil {
		t.Estado = repository.TrabajoFallido
		t.Error = mensajeTrabajo(err)
	} else {
		t.Estado = repository.TrabajoCompletado
		t.Resultado = comoDocumento(informe)
	}
	if errAct := s.trabajoRepo.Actualizar(ctx, &t); errAct != nil {
		s.log.Warn("no se pudo guardar el resultado del trabajo", applog.Err(errAct))
	}
}

// ObtenerTrabajo devuelve un trabajo; solo lo consulta quien lo creó o un actor sin
// restricción de ámbito.
func (s *Service) ObtenerTrabajo(ctx context.Context, actor ContextoActor, id string) (*repository.Trabajo, error) {
	if s.trabajoRepo == nil {
		return nil, ErrTrabajosNoDisponibles
	}
	t, err := s.trabajoRepo.Obtener(ctx, id)
	if err != nil {
		return nil, err
	}
	if t == nil || (t.CreadoPor != actor.UsuarioID && actor.alcanceEfectivo() != nil) {
		return nil, shared.NewNotFoundError("Trabajo", id)
	}
	return t, nil
}

func mensajeTrabajo(err error) string {
	var de *shared.DomainError
	if errors.As(err, &de) {
		return de.Message
	}
	if errors.Is(err, ErrFueraDeAmbitoFacultad) {
		return err.Error()
	}
	return "La generación no pudo completarse; inténtalo de nuevo"
}

// comoDocumento guarda el resultado con los mismos nombres de campo que la respuesta JSON.
func comoDocumento(v interface{}) map[string]interface{} {
	crudo, err := json.Marshal(v)
	if err != nil {
		return nil
	}
	var doc map[string]interface{}
	if json.Unmarshal(crudo, &doc) != nil {
		return nil
	}
	return doc
}
