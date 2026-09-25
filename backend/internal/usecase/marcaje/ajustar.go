// Package marcaje — caso de uso para ajustes y anulaciones administrativas de marcajes.
// Satisface US-MAR-09 (AC-01..AC-06), T-MAR-09.1, T-MAR-09.2, T-MAR-09.3 y RF-AUD-001.
package marcaje

import (
	"context"
	"fmt"
	"math"
	"strings"
	"time"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
)

// SolicitudAjuste contiene los datos requeridos para anular o corregir un marcaje.
type SolicitudAjuste struct {
	MarcajeID      string                         `json:"marcajeId"`
	NuevoResultado domainMarcaje.ResultadoMarcaje `json:"nuevoResultado,omitempty"`
	Anulado        bool                           `json:"anulado"`
	Motivo         string                         `json:"motivo"` // Mínimo 20 caracteres obligatorio (AC-01)
}

// SolicitudMarcajeManual contiene los datos para crear un registro manual por contingencia.
type SolicitudMarcajeManual struct {
	SesionID  string                         `json:"sesionId"`
	UsuarioID string                         `json:"usuarioId"`
	Tipo      domainMarcaje.TipoMarcaje      `json:"tipo"`
	Resultado domainMarcaje.ResultadoMarcaje `json:"resultado"`
	Motivo    string                         `json:"motivo"` // Mínimo 20 caracteres obligatorio
}

// AjustarMarcajeUseCase coordina las modificaciones con motivo obligatorio y bitácora de auditoría.
type AjustarMarcajeUseCase struct {
	marcajeRepo   repository.MarcajeRepository
	sesionRepo    repository.SesionRepository
	auditoriaRepo repository.AuditoriaRepository
}

func NewAjustarMarcajeUseCase(
	marcajeRepo repository.MarcajeRepository,
	sesionRepo repository.SesionRepository,
	auditoriaRepo repository.AuditoriaRepository,
) *AjustarMarcajeUseCase {
	return &AjustarMarcajeUseCase{
		marcajeRepo:   marcajeRepo,
		sesionRepo:    sesionRepo,
		auditoriaRepo: auditoriaRepo,
	}
}

// Ajustar aplica anulación o corrección técnica garantizando motivo >= 20 caracteres y auditoría completa (AC-01, AC-02, AC-06).
func (uc *AjustarMarcajeUseCase) Ajustar(ctx context.Context, req SolicitudAjuste, ajustadorID string) (*domainMarcaje.Marcaje, error) {
	motivo := strings.TrimSpace(req.Motivo)
	if len(motivo) < 20 {
		return nil, domainMarcaje.ErrMotivoInsuficiente
	}

	original, err := uc.marcajeRepo.ObtenerPorID(ctx, req.MarcajeID)
	if err != nil || original == nil {
		return nil, fmt.Errorf("marcaje no encontrado: %s", req.MarcajeID)
	}

	ahora := time.Now().UTC()
	actualizado, errAct := uc.marcajeRepo.ActualizarAjuste(
		ctx,
		req.MarcajeID,
		req.NuevoResultado,
		req.Anulado,
		motivo,
		ajustadorID,
		ahora,
	)
	if errAct != nil {
		return nil, fmt.Errorf("error aplicando ajuste: %w", errAct)
	}

	// AC-06: Generar entrada de auditoría con valores anterior y nuevo completos
	if uc.auditoriaRepo != nil {
		_ = uc.auditoriaRepo.Create(ctx, &repository.AuditEntry{
			Entidad:       "marcajes",
			EntidadID:     original.ID,
			Accion:        "MARCAJE_AJUSTE_ADMINISTRATIVO",
			ActorID:       ajustadorID,
			ValorAnterior: original,
			ValorNuevo:    actualizado,
			CreadoEn:      ahora,
		})
	}

	return actualizado, nil
}

// CrearManual registra un marcaje de origen MANUAL conservando la trazabilidad de autor y motivo (AC-04).
func (uc *AjustarMarcajeUseCase) CrearManual(ctx context.Context, req SolicitudMarcajeManual, ajustadorID string) (*domainMarcaje.Marcaje, error) {
	motivo := strings.TrimSpace(req.Motivo)
	if len(motivo) < 20 {
		return nil, domainMarcaje.ErrMotivoInsuficiente
	}

	ahora := time.Now().UTC()
	m := &domainMarcaje.Marcaje{
		SesionID:             req.SesionID,
		UsuarioID:            req.UsuarioID,
		DocenteID:            req.UsuarioID,
		RolMarcaje:           domainMarcaje.RolDocente,
		Tipo:                 req.Tipo,
		Resultado:            req.Resultado,
		TimestampServidor:    ahora,
		TimestampDispositivo: ahora,
		Timestamp:            ahora,
		Origen:               domainMarcaje.OrigenManual,
		Anulado:              false,
		MotivoAjuste:         motivo,
		AjustadoPor:          ajustadorID,
		AjustadoEn:           &ahora,
		CreadoEn:             ahora,
	}

	if err := uc.marcajeRepo.Crear(ctx, m); err != nil {
		return nil, fmt.Errorf("error creando marcaje manual: %w", err)
	}

	if uc.auditoriaRepo != nil {
		_ = uc.auditoriaRepo.Create(ctx, &repository.AuditEntry{
			Entidad:    "marcajes",
			EntidadID:  m.ID,
			Accion:     "MARCAJE_CREACION_MANUAL",
			ActorID:    ajustadorID,
			ValorNuevo: m,
			CreadoEn:   ahora,
		})
	}

	return m, nil
}

// ListarAdministrativo lista marcajes con filtros para supervisores y coordinadores.
func (uc *AjustarMarcajeUseCase) ListarAdministrativo(ctx context.Context, f repository.FiltrosMarcaje, pagina, limite int64) (*RespuestaHistorial, error) {
	if pagina < 1 {
		pagina = 1
	}
	if limite <= 0 || limite > 100 {
		limite = 20
	}
	skip := (pagina - 1) * limite

	items, total, err := uc.marcajeRepo.ListarConFiltros(ctx, f, skip, limite)
	if err != nil {
		return nil, err
	}

	totalPaginas := int64(math.Ceil(float64(total) / float64(limite)))
	if totalPaginas == 0 {
		totalPaginas = 1
	}

	return &RespuestaHistorial{
		Items:        items,
		Total:        total,
		Pagina:       pagina,
		Limite:       limite,
		TotalPaginas: totalPaginas,
	}, nil
}
