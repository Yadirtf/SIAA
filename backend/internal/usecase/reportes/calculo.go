package reportes

import (
	"math"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/justificacion"
	"github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/domain/parametro"
)

// FilaDocente agrega el cumplimiento de un docente (o los totales).
type FilaDocente struct {
	DocenteID              string  `json:"docenteId,omitempty"`
	Nombre                 string  `json:"nombre,omitempty"`
	Documento              string  `json:"documento,omitempty"`
	Sesiones               int     `json:"sesiones"`
	HorasProgramadas       float64 `json:"horasProgramadas"`
	HorasDictadas          float64 `json:"horasDictadas"`
	HorasJustificadas      float64 `json:"horasJustificadas"`
	Presentes              int     `json:"presentes"`
	Tardanzas              int     `json:"tardanzas"`
	AusenciasJustificadas  int     `json:"ausenciasJustificadas"`
	AusenciasInjustificada int     `json:"ausenciasInjustificadas"`
	Ajustadas              int     `json:"ajustadas"`
	// SalidasFaltantes: sesiones dictadas con salida OBLIGATORIA sin marcaje de salida (US-MAR-15 AC-01).
	SalidasFaltantes int `json:"salidasFaltantes"`
	// BajoUmbral: el cumplimiento está por debajo de porcentaje_minimo_asistencia (US-PAR-04 AC-01).
	BajoUmbral bool `json:"bajoUmbral"`
	// PorcentajeCumplimiento = dictadas / (programadas − justificadas).
	PorcentajeCumplimiento float64 `json:"porcentajeCumplimiento"`
}

type clave struct{ sesion, docente string }

type agregador struct {
	entradas       map[clave]*marcaje.Marcaje
	salidas        map[clave]*marcaje.Marcaje
	justificadas   map[clave]bool
	filas          map[string]*FilaDocente
	falsosRechazos int
}

func nuevoAgregador(entradas, salidas []*marcaje.Marcaje, aprobadas []*justificacion.Justificacion) *agregador {
	a := &agregador{
		entradas:     indexar(entradas),
		salidas:      indexar(salidas),
		justificadas: map[clave]bool{},
		filas:        map[string]*FilaDocente{},
	}
	for _, j := range aprobadas {
		a.justificadas[clave{j.SesionID, j.DocenteID}] = true
		if j.Tipo == justificacion.TipoFallaTecnica {
			a.falsosRechazos++
		}
	}
	return a
}

// sumar clasifica la sesión del docente: dictada (a tiempo o con tardanza) si tiene
// entrada válida vigente; justificada si hay una justificación aprobada; si no, ausencia.
func (a *agregador) sumar(s *academico.Sesion, docenteID string) {
	f := a.filas[docenteID]
	if f == nil {
		f = &FilaDocente{DocenteID: docenteID}
		a.filas[docenteID] = f
	}
	horas := s.FinProgramado().Sub(s.InicioProgramado()).Hours()
	f.Sesiones++
	f.HorasProgramadas += horas

	k := clave{s.ID(), docenteID}
	m := a.entradas[k]
	switch {
	case m != nil && m.EsExitoso():
		f.HorasDictadas += horas
		if m.Resultado == marcaje.ResultadoTardanza || m.Resultado == marcaje.ResultadoRetardo {
			f.Tardanzas++
		} else {
			f.Presentes++
		}
		if m.Origen == marcaje.OrigenAjuste || m.Origen == marcaje.OrigenManual {
			f.Ajustadas++
		}
		if salidaObligatoria(s) && !exitoso(a.salidas[k]) {
			f.SalidasFaltantes++
		}
	case a.justificadas[k]:
		f.HorasJustificadas += horas
		f.AusenciasJustificadas++
	default:
		f.AusenciasInjustificada++
	}
}

// resultado devuelve las filas por docente y la fila de totales, con porcentajes.
func (a *agregador) resultado(umbral float64) ([]FilaDocente, FilaDocente) {
	filas := make([]FilaDocente, 0, len(a.filas))
	var t FilaDocente
	for _, f := range a.filas {
		f.PorcentajeCumplimiento = porcentaje(f)
		f.BajoUmbral = f.PorcentajeCumplimiento < umbral
		filas = append(filas, *f)
		t.Sesiones += f.Sesiones
		t.HorasProgramadas += f.HorasProgramadas
		t.HorasDictadas += f.HorasDictadas
		t.HorasJustificadas += f.HorasJustificadas
		t.Presentes += f.Presentes
		t.Tardanzas += f.Tardanzas
		t.AusenciasJustificadas += f.AusenciasJustificadas
		t.AusenciasInjustificada += f.AusenciasInjustificada
		t.Ajustadas += f.Ajustadas
		t.SalidasFaltantes += f.SalidasFaltantes
	}
	t.PorcentajeCumplimiento = porcentaje(&t)
	t.BajoUmbral = t.PorcentajeCumplimiento < umbral
	return filas, t
}

func porcentaje(f *FilaDocente) float64 {
	exigibles := f.HorasProgramadas - f.HorasJustificadas
	if exigibles <= 0 {
		return 100
	}
	return math.Round(f.HorasDictadas/exigibles*1000) / 10
}

// indexar agrupa los marcajes consolidados por sesión y usuario.
func indexar(marcajes []*marcaje.Marcaje) map[clave]*marcaje.Marcaje {
	res := make(map[clave]*marcaje.Marcaje, len(marcajes))
	for _, m := range marcajes {
		usuario := m.UsuarioID
		if usuario == "" {
			usuario = m.DocenteID
		}
		res[clave{m.SesionID, usuario}] = m
	}
	return res
}

func exitoso(m *marcaje.Marcaje) bool { return m != nil && m.EsExitoso() }

// salidaObligatoria lee el modo de salida congelado en la sesión (RN-002).
func salidaObligatoria(s *academico.Sesion) bool {
	return s.ParametrosCongelados()[string(parametro.ClaveSalidaObligatoria)] == parametro.SalidaObligatoria
}
