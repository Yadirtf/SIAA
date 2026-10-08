package unit_test

import (
	"context"
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
	usecaseMarcaje "github.com/siaa/backend/internal/usecase/marcaje"
)

type sesionesGrupoFake struct {
	repository.SesionRepository
	lista []*academico.Sesion
}

func (f *sesionesGrupoFake) List(_ context.Context, _ repository.SesionFilter) ([]*academico.Sesion, error) {
	return f.lista, nil
}

type consolidadosFake struct {
	repository.MarcajeRepository
	lista []*domainMarcaje.Marcaje
}

func (f *consolidadosFake) ListarConsolidados(_ context.Context, ids []string, _ domainMarcaje.TipoMarcaje) ([]*domainMarcaje.Marcaje, error) {
	permitidas := map[string]bool{}
	for _, id := range ids {
		permitidas[id] = true
	}
	var res []*domainMarcaje.Marcaje
	for _, m := range f.lista {
		if permitidas[m.SesionID] {
			res = append(res, m)
		}
	}
	return res, nil
}

type integrantesFake struct {
	repository.GrupoEstudiantesRepository
	grupos map[string][]string
}

func (f *integrantesFake) Listar(_ context.Context, g string) ([]string, error) {
	return f.grupos[g], nil
}
func (f *integrantesFake) GruposDeEstudiante(_ context.Context, est string) ([]string, error) {
	var res []string
	for g, ids := range f.grupos {
		for _, id := range ids {
			if id == est {
				res = append(res, g)
			}
		}
	}
	return res, nil
}

func sesionGrupo(id string, inicio time.Time, estado academico.EstadoSesion) *academico.Sesion {
	return academico.ReconstituirSesion(id, "P", "A", "ASIG", "G1", []string{"DOC"}, "E", inicio.Format("2006-01-02"),
		"08:00", "10:00", inicio, inicio.Add(2*time.Hour), inicio, inicio.Add(15*time.Minute), nil, nil, estado, 1, nil, nil,
		map[string]interface{}{"porcentaje_minimo_asistencia": 80}, "", inicio, inicio)
}

// US-MAR-13 AC-05 y US-REP-05: el porcentaje cuenta solo sesiones terminadas y dictadas, y el
// del estudiante coincide con el del reporte del grupo.
func TestAsistenciaEstudiante_PorcentajeYUmbral(t *testing.T) {
	ahora := time.Date(2026, 10, 8, 12, 0, 0, 0, time.UTC)
	dia := func(d int) time.Time { return ahora.AddDate(0, 0, -d).Truncate(24 * time.Hour).Add(13 * time.Hour) }
	sesiones := []*academico.Sesion{
		sesionGrupo("S1", dia(3), academico.EstadoSesionRealizada),
		sesionGrupo("S2", dia(2), academico.EstadoSesionRealizada),
		sesionGrupo("S3", dia(1), academico.EstadoSesionProgramada),
		sesionGrupo("S4", dia(4), academico.EstadoSesionCancelada),
		sesionGrupo("S5", ahora.Add(24*time.Hour), academico.EstadoSesionProgramada),
	}
	marcajes := []*domainMarcaje.Marcaje{
		{SesionID: "S1", UsuarioID: "EST1", Resultado: domainMarcaje.ResultadoPresente},
		{SesionID: "S2", UsuarioID: "EST1", Resultado: domainMarcaje.ResultadoTardanza},
		{SesionID: "S3", UsuarioID: "EST1", Resultado: domainMarcaje.ResultadoAusente},
		{SesionID: "S4", UsuarioID: "EST1", Resultado: domainMarcaje.ResultadoPresente},
		{SesionID: "S1", UsuarioID: "EST2", Resultado: domainMarcaje.ResultadoPresente},
		{SesionID: "S2", UsuarioID: "EST2", Resultado: domainMarcaje.ResultadoPresente},
		{SesionID: "S3", UsuarioID: "EST2", Resultado: domainMarcaje.ResultadoPresente},
	}
	uc := usecaseMarcaje.NewAsistenciaEstudianteUseCase(&sesionesGrupoFake{lista: sesiones},
		&consolidadosFake{lista: marcajes}, &integrantesFake{grupos: map[string][]string{"G1": {"EST1", "EST2"}}}, nil).
		WithReloj(func() time.Time { return ahora })

	propia, err := uc.DelEstudiante(context.Background(), "EST1")
	if err != nil || len(propia) != 1 {
		t.Fatalf("asistencia propia: %v, %v", propia, err)
	}
	if p := propia[0]; p.Dictadas != 3 || p.Asistidas != 2 || p.Porcentaje != 66.7 || !p.BajoUmbral || p.Umbral != 80 {
		t.Fatalf("acumulado inesperado: %+v", p)
	}
	grupo, _ := uc.DelGrupo(context.Background(), "G1")
	if len(grupo) != 2 || grupo[0].Porcentaje != propia[0].Porcentaje || grupo[1].Porcentaje != 100 || grupo[1].BajoUmbral {
		t.Fatalf("el reporte del grupo debe coincidir con la vista del estudiante: %+v", grupo)
	}
}
