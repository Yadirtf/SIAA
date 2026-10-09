package privacidad

import (
	"testing"
	"time"
)

func TestSumarDiasHabiles(t *testing.T) {
	// Viernes 9 de octubre de 2026, 10:00 en Bogotá: 15 días hábiles terminan el viernes 30.
	viernes := time.Date(2026, 10, 9, 15, 0, 0, 0, time.UTC)
	fin := SumarDiasHabiles(viernes, DiasHabilesReclamo)
	if got := fin.In(time.FixedZone("COT", -5*3600)).Format("2006-01-02 15:04"); got != "2026-10-30 23:59" {
		t.Fatalf("plazo de reclamo: %s", got)
	}
}

func TestNuevaSolicitud(t *testing.T) {
	ahora := time.Now()
	if _, err := NuevaSolicitud("u", "OTRO", "descripción suficiente", nil, ahora); err == nil {
		t.Fatal("tipo inválido")
	}
	if _, err := NuevaSolicitud("u", SolicitudRectificacion, "descripción suficiente", map[string]string{"correo": "x@y"}, ahora); err == nil {
		t.Fatal("la rectificación exige un campo rectificable")
	}
	s, err := NuevaSolicitud("u", SolicitudRectificacion, "  mi nombre está mal  ", map[string]string{"nombre": " Ana ", "correo": "x@y"}, ahora)
	if err != nil || len(s.Cambios) != 1 || s.Cambios["nombre"] != "Ana" || s.Estado != SolicitudRadicada {
		t.Fatalf("solicitud: %+v %v", s, err)
	}
	if !s.VenceEn.After(ahora.AddDate(0, 0, 20)) || s.Vencida(ahora) || !s.Vencida(s.VenceEn.Add(time.Second)) {
		t.Fatalf("plazo: %v", s.VenceEn)
	}
	if err := s.Asignar("admin", "admin", ahora); err != nil || s.Estado != SolicitudEnTramite || s.ResponsableID != "admin" {
		t.Fatalf("asignar: %+v %v", s, err)
	}
	if err := s.Resolver("admin", false, "corta", ahora); err == nil {
		t.Fatal("la respuesta es obligatoria")
	}
	if err := s.Resolver("admin", false, "No se aportó soporte del cambio", ahora); err != nil || s.Estado != SolicitudDenegada || s.Abierta() {
		t.Fatalf("resolver: %+v %v", s, err)
	}
	if err := s.Resolver("admin", true, "Otra respuesta cualquiera", ahora); err == nil {
		t.Fatal("un caso resuelto no se resuelve de nuevo")
	}
	if len(s.Historial) != 3 {
		t.Fatalf("historial: %+v", s.Historial)
	}
}

func TestEvaluarSupresion(t *testing.T) {
	decision := func(lista []ElementoSupresion, cat string) DecisionSupresion {
		for _, e := range lista {
			if e.Fundamento == "" {
				t.Fatalf("sin fundamento: %+v", e)
			}
			if e.Categoria == cat {
				return e.Decision
			}
		}
		return ""
	}
	libre := EvaluarSupresion(false)
	if decision(libre, CategoriaUbicaciones) != SeElimina || decision(libre, CategoriaAsistencia) != SeConserva || decision(libre, CategoriaConsentimientos) != SeConserva {
		t.Fatalf("evaluación: %+v", libre)
	}
	if decision(EvaluarSupresion(true), CategoriaUbicaciones) != SeConserva {
		t.Fatal("bajo investigación las ubicaciones se conservan")
	}
}
