package marcaje

import (
	"context"

	"github.com/siaa/backend/internal/domain/academico"
	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	"github.com/siaa/backend/internal/repository"
)

// WithGrupoEstudiantes habilita el marcaje estudiantil (US-MAR-13): quien integra el grupo de
// la sesión marca como ESTUDIANTE dentro de la ventana que abrió el docente.
func (uc *CrearMarcajeUseCase) WithGrupoEstudiantes(r repository.GrupoEstudiantesRepository) *CrearMarcajeUseCase {
	uc.grupoEstRepo = r
	return uc
}

// completarEstudiante añade al contexto la pertenencia del usuario al grupo y la ventana
// estudiantil vigente. Un docente de la sesión nunca se trata como estudiante.
func (uc *CrearMarcajeUseCase) completarEstudiante(ctx context.Context, info *domainMarcaje.SesionInfo, s *academico.Sesion, usuarioID string) {
	if v := s.VentanaEstudiantil(); v != nil {
		info.VentanaEstudiantilAbierta = v.Abierta
		info.VentanaEstudiantilAbre = v.AbiertaEn
		info.VentanaEstudiantilCierra = v.CierraEn
	}
	if uc.grupoEstRepo == nil || usuarioID == "" || s.TieneDocente(usuarioID) || s.GrupoID() == "" {
		return
	}
	if ok, err := uc.grupoEstRepo.Pertenece(ctx, s.GrupoID(), usuarioID); err == nil && ok {
		info.EstudianteIDs = []string{usuarioID}
	}
}

// rolSegunSesion decide con qué rol se evalúa el marcaje: el cliente no lo elige.
func rolSegunSesion(req domainMarcaje.SolicitudMarcaje, info *domainMarcaje.SesionInfo) domainMarcaje.RolMarcaje {
	if info != nil && req.UsuarioID != "" && info.SuplenteID != req.UsuarioID {
		for _, id := range info.EstudianteIDs {
			if id == req.UsuarioID {
				return domainMarcaje.RolEstudiante
			}
		}
	}
	return domainMarcaje.RolDocente
}
