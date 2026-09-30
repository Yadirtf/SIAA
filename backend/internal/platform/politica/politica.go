// Package politica publica el aviso de privacidad y la política de tratamiento (RNF-LEG-003).
// El texto vive en politica.md; al cambiarlo se debe subir Version para que los titulares
// vuelvan a aceptar (US-LEG-01 AC-03).
package politica

import (
	_ "embed"
	"strings"

	"github.com/siaa/backend/internal/domain/privacidad"
)

// Version de la política vigente. Súbala cada vez que cambie politica.md.
const Version = "1.0"

// ActualizadaEn es la fecha de publicación de la versión vigente.
const ActualizadaEn = "2026-09-30"

//go:embed politica.md
var plantilla string

// Construir completa la plantilla con la institución responsable y su canal de atención.
func Construir(institucion, contacto string) privacidad.Politica {
	if institucion == "" {
		institucion = "la institución de educación superior que opera SIAA"
	}
	if contacto == "" {
		contacto = "la oficina de protección de datos personales de la institución"
	}
	contenido := strings.NewReplacer("{{INSTITUCION}}", institucion, "{{CONTACTO}}", contacto).Replace(plantilla)
	return privacidad.Politica{
		Version:       Version,
		Contenido:     contenido,
		ActualizadaEn: ActualizadaEn,
		Institucion:   institucion,
		Contacto:      contacto,
	}
}
