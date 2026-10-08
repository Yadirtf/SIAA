package importar

// columnasPlantilla y ejemploPlantilla forman la plantilla publicada de carga académica
// (T-ACA-07.1). docente acepta documento o correo; dia acepta 1-7 o el nombre del día.
var (
	columnasPlantilla = []string{"periodo", "facultad", "programa", "asignatura", "asignaturaNombre",
		"grupo", "docente", "aula", "dia", "horaInicio", "horaFin", "modalidad"}
	ejemploPlantilla = []string{"2026-1", "FAC-ING", "PROG-SIS", "ASIG-101", "Programación I",
		"01", "1032456789", "AULA-101", "lunes", "07:00", "09:00", "PRESENCIAL"}
)

// Plantilla devuelve la plantilla vacía con una fila de ejemplo en CSV o XLSX.
func Plantilla(formato string) ([]byte, string, error) {
	t := &Tabla{Formato: formato, Separador: ',', Encabezados: columnasPlantilla,
		Filas: []Fila{{Numero: 2, Celdas: ejemploPlantilla}}}
	return escribir(t, nil)
}
