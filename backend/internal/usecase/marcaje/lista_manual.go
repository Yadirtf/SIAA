// Package marcaje — caso de uso para registro de lista manual por el docente.
// Satisface US-MAR-14 (AC-01..AC-04) y RF-MAR-013.
package marcaje

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/repository"
)

var (
	ErrMotivoListaRequerido = errors.New("el motivo del uso de la lista manual es obligatorio (US-MAR-14 AC-03)")
)

// ItemListaEstudiante representa el pase de lista para un alumno particular.
type ItemListaEstudiante struct {
	EstudianteID string `json:"estudianteId"`
	Presente     bool   `json:"presente"`
}

// ResultadoListaManual informa qué se registró y qué se dejó como estaba.
type ResultadoListaManual struct {
	Registrados int `json:"registrados"`
	// Conservados: ya tenían un marcaje válido (por geolocalización o lista previa) (AC-04).
	Conservados int `json:"conservados"`
	// NoPertenecen: identificadores que no integran el grupo; no se registran.
	NoPertenecen []string `json:"noPertenecen"`
}

// ListaManualUseCase registra la asistencia manual como respaldo preservando los marcajes geolocalizados.
type ListaManualUseCase struct {
	sesionRepo    repository.SesionRepository
	marcajeRepo   repository.MarcajeRepository
	auditoriaRepo repository.AuditoriaRepository
	grupoEstRepo  repository.GrupoEstudiantesRepository
	usuarioRepo   repository.UsuarioRepository
	reloj         func() time.Time
}

func NewListaManualUseCase(
	sesionRepo repository.SesionRepository,
	marcajeRepo repository.MarcajeRepository,
	auditoriaRepo repository.AuditoriaRepository,
) *ListaManualUseCase {
	return &ListaManualUseCase{
		sesionRepo:    sesionRepo,
		marcajeRepo:   marcajeRepo,
		auditoriaRepo: auditoriaRepo,
		reloj:         func() time.Time { return time.Now().UTC() },
	}
}

// WithGrupo habilita la lista del grupo: solo sus integrantes se pueden registrar (AC-01).
func (uc *ListaManualUseCase) WithGrupo(grupos repository.GrupoEstudiantesRepository, usuarios repository.UsuarioRepository) *ListaManualUseCase {
	uc.grupoEstRepo = grupos
	uc.usuarioRepo = usuarios
	return uc
}

// WithReloj fija el reloj (pruebas).
func (uc *ListaManualUseCase) WithReloj(reloj func() time.Time) *ListaManualUseCase {
	uc.reloj = reloj
	return uc
}

// Registrar guarda el pase de lista manual de los estudiantes verificando la precedencia geolocalizada (AC-04).
func (uc *ListaManualUseCase) Registrar(ctx context.Context, sesionID, docenteID string, motivo string, items []ItemListaEstudiante) (*ResultadoListaManual, error) {
	motivo = strings.TrimSpace(motivo)
	if motivo == "" {
		return nil, ErrMotivoListaRequerido
	}
	ahora := uc.reloj()
	s, err := uc.sesionDelDocente(ctx, sesionID, docenteID, ahora)
	if err != nil {
		return nil, err
	}
	integrantes, err := uc.integrantes(ctx, s)
	if err != nil {
		return nil, err
	}
	res := &ResultadoListaManual{NoPertenecen: []string{}}
	for _, item := range items {
		if integrantes != nil && !integrantes[item.EstudianteID] {
			res.NoPertenecen = append(res.NoPertenecen, item.EstudianteID)
			continue
		}
		// AC-04: un marcaje válido previo (geolocalizado o de otra lista) prevalece.
		previo, _ := uc.marcajeRepo.ObtenerPrevio(ctx, sesionID, item.EstudianteID, domainMarcaje.TipoEntrada)
		if previo != nil && previo.ConsolidaSesion() {
			res.Conservados++
			continue
		}
		if err := uc.marcajeRepo.Crear(ctx, marcajeManual(sesionID, docenteID, motivo, item, ahora)); err == nil {
			res.Registrados++
		} else {
			res.Conservados++
		}
	}
	// AC-03: Auditoría obligatoria del uso de la lista manual
	if uc.auditoriaRepo != nil {
		_ = uc.auditoriaRepo.Create(ctx, &repository.AuditEntry{
			Entidad: "sesiones", EntidadID: sesionID, Accion: "LISTA_MANUAL_DOCENTE", ActorID: docenteID,
			ValorNuevo: map[string]interface{}{"motivo": motivo, "registrados": res.Registrados,
				"conservados": res.Conservados, "noPertenecen": res.NoPertenecen},
			CreadoEn: ahora,
		})
	}
	return res, nil
}

func marcajeManual(sesionID, docenteID, motivo string, item ItemListaEstudiante, ahora time.Time) *domainMarcaje.Marcaje {
	resultado := domainMarcaje.ResultadoPresente
	if !item.Presente {
		resultado = domainMarcaje.ResultadoAusente
	}
	return &domainMarcaje.Marcaje{
		SesionID:             sesionID,
		UsuarioID:            item.EstudianteID,
		DocenteID:            item.EstudianteID, // alias histórico de UsuarioID
		RolMarcaje:           domainMarcaje.RolEstudiante,
		Tipo:                 domainMarcaje.TipoEntrada,
		Resultado:            resultado,
		TimestampServidor:    ahora,
		TimestampDispositivo: ahora,
		Timestamp:            ahora,
		Origen:               domainMarcaje.OrigenManualDocente, // AC-02: origen MANUAL_DOCENTE
		MotivoAjuste:         motivo,
		AjustadoPor:          docenteID,
		AjustadoEn:           &ahora,
		CreadoEn:             ahora,
	}
}

// sesionDelDocente exige que la sesión sea del docente y que ya haya empezado su ventana de
// entrada: no se pasa lista de una clase futura ni cancelada (AC-01).
func (uc *ListaManualUseCase) sesionDelDocente(ctx context.Context, sesionID, docenteID string, ahora time.Time) (*academico.Sesion, error) {
	s, err := uc.sesionRepo.FindByID(ctx, sesionID)
	if err != nil {
		return nil, fmt.Errorf("buscar sesión: %w", err)
	}
	if s == nil {
		return nil, shared.NewNotFoundError("sesión", sesionID)
	}
	if !s.TieneDocente(docenteID) {
		return nil, ErrDocenteNoAutorizado
	}
	if s.Estado() == academico.EstadoSesionCancelada || s.Estado() == academico.EstadoSesionExcluida {
		return nil, &shared.DomainError{Code: shared.ErrEstadoInvalido, Message: "La sesión está cancelada; no admite lista de asistencia"}
	}
	if ahora.Before(s.VentanaEntradaAbre()) {
		return nil, &shared.DomainError{Code: shared.ErrEstadoInvalido, Message: "La lista manual se habilita cuando empieza la sesión"}
	}
	return s, nil
}

// integrantes devuelve el conjunto de estudiantes del grupo (nil = sin restricción configurada).
func (uc *ListaManualUseCase) integrantes(ctx context.Context, s *academico.Sesion) (map[string]bool, error) {
	if uc.grupoEstRepo == nil {
		return nil, nil
	}
	ids, err := uc.grupoEstRepo.Listar(ctx, s.GrupoID())
	if err != nil {
		return nil, err
	}
	conjunto := make(map[string]bool, len(ids))
	for _, id := range ids {
		conjunto[id] = true
	}
	return conjunto, nil
}
