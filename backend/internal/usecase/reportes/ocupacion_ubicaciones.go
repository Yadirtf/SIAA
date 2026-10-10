package reportes

import (
	"context"
	"strings"

	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/repository"
)

// ubicaciones resuelve espacio, bloque y sede con caché durante un cálculo de ocupación.
type ubicaciones struct {
	espacios repository.EspacioRepository
	bloques  repository.BloqueRepository
	sedes    repository.SedeRepository
	esp      map[string]*geo.Espacio
	nombres  map[string]string
}

func newUbicaciones(e repository.EspacioRepository, b repository.BloqueRepository, s repository.SedeRepository) *ubicaciones {
	return &ubicaciones{espacios: e, bloques: b, sedes: s, esp: map[string]*geo.Espacio{}, nombres: map[string]string{}}
}

// espacio devuelve el espacio o nil si no existe (una sesión sin aula no cuenta en la ocupación).
func (u *ubicaciones) espacio(ctx context.Context, id string) *geo.Espacio {
	if id == "" {
		return nil
	}
	if e, ok := u.esp[id]; ok {
		return e
	}
	e, err := u.espacios.FindByID(ctx, id)
	if err != nil {
		e = nil
	}
	u.esp[id] = e
	return e
}

func (u *ubicaciones) nombreBloque(ctx context.Context, id string) string {
	if id == "" {
		return ""
	}
	if v, ok := u.nombres["b:"+id]; ok {
		return v
	}
	v := id
	if u.bloques != nil {
		if b, err := u.bloques.FindByID(ctx, id); err == nil && b != nil {
			v = strings.TrimSpace(b.Codigo + " · " + b.Nombre)
		}
	}
	u.nombres["b:"+id] = v
	return v
}

func (u *ubicaciones) nombreSede(ctx context.Context, id string) string {
	if id == "" {
		return ""
	}
	if v, ok := u.nombres["s:"+id]; ok {
		return v
	}
	v := id
	if u.sedes != nil {
		if s, err := u.sedes.FindByID(ctx, id); err == nil && s != nil {
			v = s.Nombre
		}
	}
	u.nombres["s:"+id] = v
	return v
}

// filaPara devuelve la clave de agregación del espacio y la fila vacía con sus nombres.
func (u *ubicaciones) filaPara(ctx context.Context, agrupacion string, e *geo.Espacio) (string, FilaOcupacion) {
	sede := u.nombreSede(ctx, e.SedeID)
	switch agrupacion {
	case AgruparSede:
		return "s:" + e.SedeID, FilaOcupacion{ID: e.SedeID, Nombre: sede}
	case AgruparBloque:
		id := bloqueDe(e)
		nombre := u.nombreBloque(ctx, id)
		if id == "" {
			nombre = "Sin bloque"
		}
		return "b:" + e.SedeID + ":" + id, FilaOcupacion{ID: id, Nombre: nombre, Sede: sede}
	}
	return "e:" + e.ID, FilaOcupacion{
		ID: e.ID, Nombre: strings.TrimSpace(e.Codigo + " · " + e.Nombre),
		Bloque: u.nombreBloque(ctx, bloqueDe(e)), Sede: sede,
	}
}
