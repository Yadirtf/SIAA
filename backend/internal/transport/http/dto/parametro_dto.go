// Package dto — DTOs de entrada/salida para la API de parámetros.
// US-PAR-01, US-PAR-03: contratos de transporte limpios y desacoplados del dominio.
package dto

import (
	"time"

	dompar "github.com/siaa/backend/internal/domain/parametro"
)

// GuardarParametroRequest es el cuerpo de PUT /parametros.
type GuardarParametroRequest struct {
	Ambito       string      `json:"ambito"     validate:"required,oneof=GLOBAL SEDE FACULTAD BLOQUE AULA ASIGNACION"`
	AmbitoID     string      `json:"ambito_id"`
	Clave        string      `json:"clave"      validate:"required"`
	Valor        interface{} `json:"valor"      validate:"required"`
	VigenteDesde *time.Time  `json:"vigente_desde"`
}

// ParametroResponse representa un parámetro almacenado.
type ParametroResponse struct {
	ID            string      `json:"id"`
	Ambito        string      `json:"ambito"`
	AmbitoID      string      `json:"ambito_id"`
	Clave         string      `json:"clave"`
	Valor         interface{} `json:"valor"`
	ValorAnterior interface{} `json:"valor_anterior,omitempty"`
	AutorID       string      `json:"autor_id"`
	VigenteDesde  time.Time   `json:"vigente_desde"`
	CreadoEn      time.Time   `json:"creado_en"`
}

// ParametroEfectivoResponse describe una clave resuelta con su origen (US-PAR-03 AC-01).
type ParametroEfectivoResponse struct {
	Clave   string      `json:"clave"`
	Valor   interface{} `json:"valor"`
	Nivel   string      `json:"nivel"`
	NivelID string      `json:"nivel_id"`
}

// ParametrosEfectivosResponse es la respuesta de GET /parametros/efectivos.
type ParametrosEfectivosResponse struct {
	Parametros []ParametroEfectivoResponse `json:"parametros"`
}

// ToParametroResponse convierte una entidad de dominio a DTO de salida.
func ToParametroResponse(p *dompar.Parametro) ParametroResponse {
	return ParametroResponse{
		ID:            p.ID,
		Ambito:        string(p.Ambito),
		AmbitoID:      p.AmbitoID,
		Clave:         string(p.Clave),
		Valor:         p.Valor,
		ValorAnterior: p.ValorAnterior,
		AutorID:       p.AutorID,
		VigenteDesde:  p.VigenteDesde,
		CreadoEn:      p.CreadoEn,
	}
}

// ToSnapshotResponse convierte un Snapshot de dominio en la respuesta de efectivos.
func ToSnapshotResponse(snap dompar.Snapshot) ParametrosEfectivosResponse {
	items := make([]ParametroEfectivoResponse, 0, len(snap))
	for _, pe := range snap {
		items = append(items, ParametroEfectivoResponse{
			Clave:   string(pe.Clave),
			Valor:   pe.Origen.Valor,
			Nivel:   string(pe.Origen.Nivel),
			NivelID: pe.Origen.NivelID,
		})
	}
	return ParametrosEfectivosResponse{Parametros: items}
}
