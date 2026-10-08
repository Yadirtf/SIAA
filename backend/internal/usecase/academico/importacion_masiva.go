// Package academico — Importación masiva de estructura académica y horarios (US-ACA-07).
// El servidor siempre valida el archivo original: el cliente no envía filas "ya validadas".
package academico

import (
	"context"
	"fmt"
	"strings"

	"github.com/siaa/backend/internal/domain/shared"
	"github.com/siaa/backend/internal/platform/importar"
	"github.com/siaa/backend/internal/repository"
)

// PreviewImportacionAcademicaDTO es el informe por fila sin persistir nada (AC-01).
type PreviewImportacionAcademicaDTO struct {
	Formato       string                     `json:"formato"`
	TotalFilas    int                        `json:"totalFilas"`
	FilasValidas  int                        `json:"filasValidas"`
	FilasConError int                        `json:"filasConError"`
	UmbralPct     float64                    `json:"umbralErroresPct"`
	SuperaUmbral  bool                       `json:"superaUmbral"`
	Filas         []FilaImportacionAcademica `json:"filas"`
}

// ResultadoImportacionAcademicaDTO es el resultado de aplicar la carga (AC-03, AC-06).
type ResultadoImportacionAcademicaDTO struct {
	Aplicada            bool                            `json:"aplicada"`
	CargaID             string                          `json:"cargaId,omitempty"`
	AsignacionesCreadas int                             `json:"asignacionesCreadas"`
	GruposCreados       int                             `json:"gruposCreados"`
	FilasOmitidas       int                             `json:"filasOmitidas"`
	Mensaje             string                          `json:"mensaje"`
	Informe             *PreviewImportacionAcademicaDTO `json:"informe"`
}

// umbralErroresDefecto es el porcentaje de filas con error que aún permite aplicar la carga.
const umbralErroresDefecto = 5.0

// WithCargasMasivas inyecta el almacén del archivo original y el umbral configurado (AC-03, AC-06).
func (s *Service) WithCargasMasivas(repo repository.CargaMasivaRepository, umbralPct float64) *Service {
	s.cargasRepo = repo
	if umbralPct >= 0 {
		s.umbralImportacion = &umbralPct
	}
	return s
}

func (s *Service) umbralErrores() float64 {
	if s.umbralImportacion != nil {
		return *s.umbralImportacion
	}
	return umbralErroresDefecto
}

// PreviewImportacion valida el archivo CSV o XLSX completo sin persistir (AC-01, AC-04, AC-05).
func (s *Service) PreviewImportacion(ctx context.Context, actor ContextoActor, contenido []byte) (*PreviewImportacionAcademicaDTO, error) {
	prev, _, _, err := s.analizarImportacion(ctx, actor, contenido)
	return prev, err
}

// DiagnosticoImportacion devuelve el mismo archivo con una columna de diagnóstico por fila (AC-02).
func (s *Service) DiagnosticoImportacion(ctx context.Context, actor ContextoActor, contenido []byte) ([]byte, string, error) {
	prev, tabla, _, err := s.analizarImportacion(ctx, actor, contenido)
	if err != nil {
		return nil, "", err
	}
	diagnosticos := make(map[int]string, len(prev.Filas))
	for _, f := range prev.Filas {
		partes := append(append([]string{}, f.Errores...), prefijar("Advertencia: ", f.Advertencias)...)
		if len(f.Errores) > 0 {
			partes[0] = "ERROR: " + partes[0]
		}
		diagnosticos[f.NumeroFila] = strings.Join(partes, " | ")
	}
	return importar.Anotar(tabla, diagnosticos)
}

// ConfirmarImportacion revalida y aplica la carga como un lote: si las filas con error superan
// el umbral no se aplica nada; si falla una escritura se revierte lo creado (AC-03, AC-06).
func (s *Service) ConfirmarImportacion(ctx context.Context, actor ContextoActor, nombre string, contenido []byte) (*ResultadoImportacionAcademicaDTO, error) {
	prev, tabla, planes, err := s.analizarImportacion(ctx, actor, contenido)
	if err != nil {
		return nil, err
	}
	res := &ResultadoImportacionAcademicaDTO{Informe: prev, FilasOmitidas: prev.FilasConError}
	if prev.SuperaUmbral || len(planes) == 0 {
		res.FilasOmitidas = prev.TotalFilas
		res.Mensaje = fmt.Sprintf("No se aplicó nada: %d de %d filas tienen errores (umbral %.1f%%).",
			prev.FilasConError, prev.TotalFilas, prev.UmbralPct)
		return res, nil
	}
	creadas, grupos, err := s.aplicarPlanes(ctx, planes)
	if err != nil {
		return nil, err
	}
	res.Aplicada, res.AsignacionesCreadas, res.GruposCreados = true, creadas, grupos
	res.CargaID = shared.NewID()
	resumen := map[string]interface{}{"archivo": nombre, "formato": tabla.Formato, "totalFilas": prev.TotalFilas,
		"asignacionesCreadas": creadas, "gruposCreados": grupos, "filasOmitidas": prev.FilasConError}
	if s.cargasRepo != nil {
		if err := s.cargasRepo.Guardar(ctx, &repository.CargaMasiva{ID: res.CargaID, Nombre: nombre,
			Formato: tabla.Formato, Contenido: contenido, ActorID: actor.UsuarioID, Resumen: resumen, CreadoEn: s.clk.Now()}); err != nil {
			s.log.Warn("no se guardó el archivo original de la carga masiva: " + err.Error())
		}
	}
	s.auditar(ctx, "carga_masiva", res.CargaID, "CARGA_MASIVA_ACADEMICA", actor, nil, resumen)
	res.Mensaje = fmt.Sprintf("Carga aplicada: %d asignaciones y %d grupos creados; %d filas omitidas por errores.",
		creadas, grupos, prev.FilasConError)
	return res, nil
}

// analizarImportacion lee el archivo, valida cada fila y calcula si supera el umbral.
func (s *Service) analizarImportacion(ctx context.Context, actor ContextoActor, contenido []byte) (*PreviewImportacionAcademicaDTO, *importar.Tabla, []*planFila, error) {
	tabla, err := importar.Leer(contenido)
	if err != nil {
		return nil, nil, nil, shared.NewValidationError("No se pudo leer el archivo: "+err.Error(),
			shared.FieldError{Campo: "archivo", Error: "ARCHIVO_INVALIDO"})
	}
	if len(tabla.Filas) == 0 {
		return nil, nil, nil, shared.NewValidationError("El archivo no tiene filas de datos",
			shared.FieldError{Campo: "archivo", Error: "SIN_FILAS"})
	}
	idx := indiceColumnas(tabla.Encabezados)
	filas := make([]FilaImportacionAcademica, 0, len(tabla.Filas))
	for _, f := range tabla.Filas {
		filas = append(filas, parsearFila(f, idx))
	}
	planes := s.validarFilas(ctx, actor, filas)
	prev := &PreviewImportacionAcademicaDTO{Formato: tabla.Formato, TotalFilas: len(filas), Filas: filas, UmbralPct: s.umbralErrores()}
	for _, f := range filas {
		if f.Valida {
			prev.FilasValidas++
		} else {
			prev.FilasConError++
		}
	}
	prev.SuperaUmbral = float64(prev.FilasConError)*100 > prev.UmbralPct*float64(prev.TotalFilas)
	return prev, tabla, planes, nil
}

func prefijar(p string, l []string) []string {
	out := make([]string, len(l))
	for i, v := range l {
		out[i] = p + v
	}
	return out
}
