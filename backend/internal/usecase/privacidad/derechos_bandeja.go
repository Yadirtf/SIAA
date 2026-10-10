package privacidad

import (
	"context"
	"strings"

	domain "github.com/siaa/backend/internal/domain/privacidad"
	"github.com/siaa/backend/internal/repository"
)

// SolicitudEnBandeja es el caso con los datos del titular y su situación frente al plazo.
type SolicitudEnBandeja struct {
	*domain.SolicitudDerecho
	TitularNombre string `json:"titularNombre"`
	TitularCorreo string `json:"titularCorreo"`
	Vencida       bool   `json:"vencida"`
}

// Listar es la bandeja de atención de la oficina de datos personales: lo que vence primero,
// primero, con el nombre del titular.
func (s *DerechosService) Listar(ctx context.Context, f repository.FiltroSolicitudesDerechos) ([]SolicitudEnBandeja, error) {
	lista, err := s.solicitudes.Listar(ctx, f, 200)
	if err != nil {
		return nil, err
	}
	ahora := s.ahora()
	nombres := map[string][2]string{}
	res := make([]SolicitudEnBandeja, 0, len(lista))
	for _, sol := range lista {
		n, ok := nombres[sol.TitularID]
		if !ok {
			if u, err := s.usuarios.FindByID(ctx, sol.TitularID); err == nil && u != nil {
				n = [2]string{strings.TrimSpace(u.Nombre + " " + u.Apellido), u.Correo}
			}
			nombres[sol.TitularID] = n
		}
		res = append(res, SolicitudEnBandeja{SolicitudDerecho: sol, TitularNombre: n[0], TitularCorreo: n[1], Vencida: sol.Vencida(ahora)})
	}
	return res, nil
}
