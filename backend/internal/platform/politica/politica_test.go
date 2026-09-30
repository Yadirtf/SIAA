package politica

import (
	"strings"
	"testing"
)

func TestConstruir(t *testing.T) {
	p := Construir("Universidad de Prueba", "datos@prueba.edu.co")
	if p.Version != Version || !strings.Contains(p.Contenido, "Universidad de Prueba") || !strings.Contains(p.Contenido, "datos@prueba.edu.co") {
		t.Fatalf("la política debe llevar institución y contacto: %+v", p)
	}
	if !strings.Contains(p.Contenido, "No existe rastreo continuo") || strings.Contains(p.Contenido, "{{") {
		t.Fatal("el aviso debe declarar que no hay rastreo continuo y no dejar marcadores sin reemplazar")
	}
	if d := Construir("", ""); d.Institucion == "" || d.Contacto == "" {
		t.Fatalf("sin configuración debe usar textos por defecto: %+v", d)
	}
}
