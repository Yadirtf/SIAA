// Package geo define las entidades de dominio para la jerarquía física y cartografía.
// T-GEO-01.1, RF-GEO-001, RF-GEO-014.
// ADR-02: el dominio no depende de infraestructura ni de frameworks externos.
package geo

import (
	"strings"
	"time"

	"github.com/siaa/backend/internal/domain/shared"
)

// TipoEspacio categoriza el uso del espacio físico.
type TipoEspacio string

const (
	TipoAula        TipoEspacio = "AULA"
	TipoLaboratorio TipoEspacio = "LABORATORIO"
	TipoAuditorio   TipoEspacio = "AUDITORIO"
	TipoTaller      TipoEspacio = "TALLER"
)

// EstadoEspacio define la disponibilidad operativa del espacio.
type EstadoEspacio string

const (
	EstadoActivo        EstadoEspacio = "ACTIVO"
	EstadoInactivo      EstadoEspacio = "INACTIVO"
	EstadoMantenimiento EstadoEspacio = "MANTENIMIENTO"
)

// NivelValidacion define el nivel de degradación espacial (Decisión D-1).
type NivelValidacion string

const (
	NivelAula   NivelValidacion = "AULA"
	NivelBloque NivelValidacion = "BLOQUE"
	NivelZona   NivelValidacion = "ZONA"
)

// Sede representa el nivel superior de la jerarquía física (ej: Campus Principal).
type Sede struct {
	ID            string
	Codigo        string
	Nombre        string
	Direccion     string
	Activo        bool
	Eliminado     bool
	CreadoEn      time.Time
	ActualizadoEn time.Time
}

// Bloque representa un edificio o estructura física dentro de una sede.
type Bloque struct {
	ID            string
	SedeID        string
	Codigo        string
	Nombre        string
	Pisos         []int
	Activo        bool
	Eliminado     bool
	CreadoEn      time.Time
	ActualizadoEn time.Time
}

// Espacio representa una unidad física donde se dictan clases o eventos (ej: Aula 301).
// RF-GEO-001, RF-GEO-014: sede y espacio obligatorios; torre, bloque y piso opcionales.
type Espacio struct {
	ID                      string
	SedeID                  string
	Torre                   *string
	BloqueID                *string
	Piso                    *int
	Codigo                  string
	Nombre                  string
	Capacidad               int
	Tipo                    TipoEspacio
	FacultadResponsable     string
	Estado                  EstadoEspacio
	NivelValidacion         NivelValidacion
	BufferMetros            float64
	Geometria               *GeoPolygon
	AreaMetrosCuadrados     float64
	Centroide               *GeoPoint
	PrecisionPromedioMetros *float64
	MetodoCaptura           *MetodoCaptura
	VersionGeometria        int
	Activo                  bool
	Eliminado               bool
	CreadoEn                time.Time
	ActualizadoEn           time.Time
}

// AsignarGeometria asigna la geometría de polígono validada al espacio, calculando
// su área geodésica en m², centroide y actualizando la versión de geometría.
// RF-GEO-002, AC-06, AC-07, T-GEO-02.1, T-GEO-02.2.
func (e *Espacio) AsignarGeometria(poligono GeoPolygon, metodo MetodoCaptura, precisionPromedio *float64) error {
	if !EsMetodoCapturaValido(metodo) {
		return shared.NewValidationError("Método de captura inválido", shared.FieldError{
			Campo: "metodoCaptura",
			Error: "MÉTODO_INVÁLIDO",
		})
	}
	if precisionPromedio != nil && *precisionPromedio < 0 {
		return shared.NewValidationError("La precisión promedio no puede ser negativa", shared.FieldError{
			Campo: "precisionPromedio",
			Error: "PRECISIÓN_INVÁLIDA",
		})
	}

	// US-GEO-03 AC-02: en captura por toque sobre mapa no se registra precisión GPS promedio
	if metodo == MetodoToqueMapa {
		precisionPromedio = nil
	}

	area := CalcularAreaGeodesica(poligono)
	centroide := CalcularCentroide(poligono)

	e.Geometria = &poligono
	e.AreaMetrosCuadrados = area
	e.Centroide = &centroide
	e.MetodoCaptura = &metodo
	e.PrecisionPromedioMetros = precisionPromedio
	e.VersionGeometria++
	e.ActualizadoEn = time.Now().UTC()
	return nil
}

// EsTipoEspacioValido valida si el tipo pertenece a los tipos permitidos por el SRS.
func EsTipoEspacioValido(t TipoEspacio) bool {
	switch t {
	case TipoAula, TipoLaboratorio, TipoAuditorio, TipoTaller:
		return true
	default:
		return false
	}
}

// EsEstadoEspacioValido valida si el estado pertenece a los estados permitidos por el SRS.
func EsEstadoEspacioValido(e EstadoEspacio) bool {
	switch e {
	case EstadoActivo, EstadoInactivo, EstadoMantenimiento:
		return true
	default:
		return false
	}
}

// EsNivelValidacionValido valida el valor de nivelValidacion (D-1).
func EsNivelValidacionValido(n NivelValidacion) bool {
	switch n {
	case NivelAula, NivelBloque, NivelZona:
		return true
	default:
		return false
	}
}

// ValidarSede valida los campos requeridos para crear una sede.
func ValidarSede(codigo, nombre string) error {
	var fields []shared.FieldError
	if strings.TrimSpace(codigo) == "" {
		fields = append(fields, shared.FieldError{Campo: "codigo", Error: "El código de la sede es obligatorio"})
	}
	if strings.TrimSpace(nombre) == "" {
		fields = append(fields, shared.FieldError{Campo: "nombre", Error: "El nombre de la sede es obligatorio"})
	}
	if len(fields) > 0 {
		return shared.NewValidationError("Datos de sede inválidos", fields...)
	}
	return nil
}

// ValidarBloque valida los campos requeridos para crear un bloque.
func ValidarBloque(sedeID, codigo, nombre string) error {
	var fields []shared.FieldError
	if strings.TrimSpace(sedeID) == "" {
		fields = append(fields, shared.FieldError{Campo: "sedeId", Error: "La sede es obligatoria"})
	}
	if strings.TrimSpace(codigo) == "" {
		fields = append(fields, shared.FieldError{Campo: "codigo", Error: "El código del bloque es obligatorio"})
	}
	if strings.TrimSpace(nombre) == "" {
		fields = append(fields, shared.FieldError{Campo: "nombre", Error: "El nombre del bloque es obligatorio"})
	}
	if len(fields) > 0 {
		return shared.NewValidationError("Datos de bloque inválidos", fields...)
	}
	return nil
}

// ValidarEspacio valida los campos requeridos según RF-GEO-001 y RF-GEO-014.
// AC-02: sede y espacio obligatorios; torre, bloque y piso opcionales.
func ValidarEspacio(sedeID, codigo, nombre string, tipo TipoEspacio, estado EstadoEspacio, capacidad int) error {
	var fields []shared.FieldError
	if strings.TrimSpace(sedeID) == "" {
		fields = append(fields, shared.FieldError{Campo: "sedeId", Error: "La sede es obligatoria"})
	}
	if strings.TrimSpace(codigo) == "" {
		fields = append(fields, shared.FieldError{Campo: "codigo", Error: "El código del espacio es obligatorio"})
	}
	if strings.TrimSpace(nombre) == "" {
		fields = append(fields, shared.FieldError{Campo: "nombre", Error: "El nombre del espacio es obligatorio"})
	}
	if !EsTipoEspacioValido(tipo) {
		fields = append(fields, shared.FieldError{Campo: "tipo", Error: "Tipo de espacio inválido (permitidos: AULA, LABORATORIO, AUDITORIO, TALLER)"})
	}
	if !EsEstadoEspacioValido(estado) {
		fields = append(fields, shared.FieldError{Campo: "estado", Error: "Estado de espacio inválido (permitidos: ACTIVO, INACTIVO, MANTENIMIENTO)"})
	}
	if capacidad < 0 {
		fields = append(fields, shared.FieldError{Campo: "capacidad", Error: "La capacidad no puede ser negativa"})
	}
	if len(fields) > 0 {
		return shared.NewValidationError("Datos de espacio inválidos", fields...)
	}
	return nil
}
