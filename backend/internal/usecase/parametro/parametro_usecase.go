// Package parametro — caso de uso para gestión y resolución de parámetros jerárquicos.
// US-PAR-01: guardar/obtener parámetros base.
// US-PAR-02: resolver cascada de herencia.
// US-PAR-03: exponer parámetro efectivo con origen.
// ADR-02: usecase orquesta; la lógica pura está en domain/parametro.
package parametro

import (
	"context"
	"time"

	dompar "github.com/siaa/backend/internal/domain/parametro"
	"github.com/siaa/backend/internal/repository"
)

// UseCase agrupa los casos de uso de parametrización jerárquica.
type UseCase struct {
	repo repository.ParametroRepository
}

// New construye el caso de uso con su dependencia.
func New(repo repository.ParametroRepository) *UseCase {
	return &UseCase{repo: repo}
}

// GuardarParametro valida y persiste un parámetro para un ámbito.
// US-PAR-01 AC-02, AC-03.
func (uc *UseCase) GuardarParametro(ctx context.Context, p *dompar.Parametro) error {
	if err := p.Validate(); err != nil {
		return err
	}
	if p.VigenteDesde.IsZero() {
		p.VigenteDesde = time.Now().UTC()
	}
	return uc.repo.Upsert(ctx, p)
}

// ListarPorAmbito obtiene los parámetros explícitamente configurados en un nivel.
func (uc *UseCase) ListarPorAmbito(ctx context.Context, ambito dompar.Ambito, ambitoID string) ([]*dompar.Parametro, error) {
	return uc.repo.ListByAmbito(ctx, ambito, ambitoID)
}

// ResolverEfectivos resuelve la cascada completa y devuelve los parámetros efectivos
// con el nivel de origen de cada clave (US-PAR-03 AC-01).
//
// ctx: contexto de la solicitud.
// spec: descripción de los ámbitos a consultar para construir la cascada.
func (uc *UseCase) ResolverEfectivos(ctx context.Context, spec EspecCascada) (dompar.Snapshot, error) {
	// Construir los filtros para recuperar solo los parámetros relevantes
	filtros := spec.toFiltros()

	todos, err := uc.repo.ListParaCascada(ctx, filtros)
	if err != nil {
		return nil, err
	}

	// Agrupar los parámetros recuperados por nivel
	capas := spec.agruparPorNivel(todos)

	// Ejecutar la función pura de resolución (US-PAR-02)
	return dompar.ResolverCascada(capas), nil
}

// EspecCascada describe los ámbitos requeridos para resolver la cascada de una asignación.
// Cada campo opcional amplía la resolución a ese nivel.
type EspecCascada struct {
	SedeID       string
	FacultadID   string
	BloqueID     string
	EspacioID    string
	AsignacionID string
}

// toFiltros construye los filtros de consulta según los ámbitos presentes.
func (e EspecCascada) toFiltros() []repository.ParametroFilter {
	nilStr := func(s string) *string {
		if s == "" {
			return nil
		}
		return &s
	}
	ambitoPtr := func(a dompar.Ambito) *dompar.Ambito { return &a }

	filtros := []repository.ParametroFilter{
		// GLOBAL no tiene ambitoID
		{Ambito: ambitoPtr(dompar.AmbitoGlobal), AmbitoID: nilStr("")},
	}
	if e.SedeID != "" {
		filtros = append(filtros, repository.ParametroFilter{
			Ambito: ambitoPtr(dompar.AmbitoSede), AmbitoID: nilStr(e.SedeID),
		})
	}
	if e.FacultadID != "" {
		filtros = append(filtros, repository.ParametroFilter{
			Ambito: ambitoPtr(dompar.AmbitoFacultad), AmbitoID: nilStr(e.FacultadID),
		})
	}
	if e.BloqueID != "" {
		filtros = append(filtros, repository.ParametroFilter{
			Ambito: ambitoPtr(dompar.AmbitoBloque), AmbitoID: nilStr(e.BloqueID),
		})
	}
	if e.EspacioID != "" {
		filtros = append(filtros, repository.ParametroFilter{
			Ambito: ambitoPtr(dompar.AmbitoAula), AmbitoID: nilStr(e.EspacioID),
		})
	}
	if e.AsignacionID != "" {
		filtros = append(filtros, repository.ParametroFilter{
			Ambito: ambitoPtr(dompar.AmbitoAsignacion), AmbitoID: nilStr(e.AsignacionID),
		})
	}
	return filtros
}

// agruparPorNivel convierte la lista plana de parámetros en capas ordenadas.
func (e EspecCascada) agruparPorNivel(parametros []*dompar.Parametro) []dompar.CapaNivel {
	mapaCapas := map[string]*dompar.CapaNivel{}

	key := func(a dompar.Ambito, id string) string { return string(a) + "|" + id }

	for _, p := range parametros {
		k := key(p.Ambito, p.AmbitoID)
		if _, ok := mapaCapas[k]; !ok {
			mapaCapas[k] = &dompar.CapaNivel{Ambito: p.Ambito, AmbitoID: p.AmbitoID}
		}
		mapaCapas[k].Parametros = append(mapaCapas[k].Parametros, p)
	}

	// Retornar en orden jerárquico (menor a mayor especificidad)
	capas := make([]dompar.CapaNivel, 0, len(dompar.NivelJerarquia))
	for _, nivel := range dompar.NivelJerarquia {
		var idBuscar string
		switch nivel {
		case dompar.AmbitoSede:
			idBuscar = e.SedeID
		case dompar.AmbitoFacultad:
			idBuscar = e.FacultadID
		case dompar.AmbitoBloque:
			idBuscar = e.BloqueID
		case dompar.AmbitoAula:
			idBuscar = e.EspacioID
		case dompar.AmbitoAsignacion:
			idBuscar = e.AsignacionID
		}
		k := key(nivel, idBuscar)
		if capa, ok := mapaCapas[k]; ok {
			capas = append(capas, *capa)
		}
	}
	return capas
}
