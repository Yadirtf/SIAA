package academico

import (
	"context"

	domainAca "github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/geo"
	"github.com/siaa/backend/internal/domain/user"
)

// catalogoImportacion resuelve los códigos del archivo contra la base real, con caché para
// no consultar la misma entidad por cada fila (US-ACA-07 AC-04).
type catalogoImportacion struct {
	s            *Service
	periodos     map[string]*domainAca.Periodo
	programas    map[string]*domainAca.Programa
	programasID  map[string]*domainAca.Programa
	facultades   map[string]*domainAca.Facultad
	asignaturas  map[string][]*domainAca.Asignatura
	grupos       map[string][]*domainAca.Grupo
	docentes     map[string]*user.Usuario
	aulas        map[string]*geo.Espacio
	asignaciones map[string][]domainAca.Asignacion
}

func (s *Service) nuevoCatalogo(ctx context.Context) *catalogoImportacion {
	c := &catalogoImportacion{s: s, periodos: map[string]*domainAca.Periodo{},
		programas: map[string]*domainAca.Programa{}, programasID: map[string]*domainAca.Programa{},
		facultades: map[string]*domainAca.Facultad{}, asignaturas: map[string][]*domainAca.Asignatura{},
		grupos: map[string][]*domainAca.Grupo{}, docentes: map[string]*user.Usuario{},
		aulas: map[string]*geo.Espacio{}, asignaciones: map[string][]domainAca.Asignacion{}}
	if ps, err := s.periodoRepo.ListAll(ctx); err == nil {
		for _, p := range ps {
			c.periodos[p.Codigo()] = p
			c.periodos[p.ID()] = p
		}
	}
	if s.estructuraRepo == nil {
		return c
	}
	if fs, err := s.estructuraRepo.ListFacultades(ctx, ""); err == nil {
		for _, f := range fs {
			c.facultades[f.Codigo()] = f
			c.facultades[f.ID()] = f
		}
	}
	if ps, err := s.estructuraRepo.ListProgramas(ctx, ""); err == nil {
		for _, p := range ps {
			c.programas[p.Codigo()] = p
			c.programasID[p.ID()] = p
		}
	}
	if as, err := s.estructuraRepo.ListAsignaturas(ctx, ""); err == nil {
		for _, a := range as {
			c.asignaturas[a.Codigo()] = append(c.asignaturas[a.Codigo()], a)
		}
	}
	return c
}

// asignatura devuelve la asignatura del código; con programa desambigua entre programas.
func (c *catalogoImportacion) asignatura(codigo string, programa *domainAca.Programa) (*domainAca.Asignatura, string) {
	candidatas := c.asignaturas[codigo]
	if programa != nil {
		for _, a := range candidatas {
			if a.ProgramaID() == programa.ID() {
				return a, ""
			}
		}
		return nil, "La asignatura '" + codigo + "' no existe en el programa '" + programa.Codigo() + "'"
	}
	switch len(candidatas) {
	case 0:
		return nil, "La asignatura '" + codigo + "' no existe"
	case 1:
		return candidatas[0], ""
	}
	return nil, "La asignatura '" + codigo + "' existe en varios programas; indique la columna programa"
}

// grupo busca el grupo por número o código externo dentro de la asignatura y el periodo.
func (c *catalogoImportacion) grupo(ctx context.Context, asignaturaID, periodoID, codigo string) *domainAca.Grupo {
	clave := asignaturaID + "|" + periodoID
	lista, ok := c.grupos[clave]
	if !ok {
		lista, _ = c.s.estructuraRepo.ListGrupos(ctx, asignaturaID, periodoID)
		c.grupos[clave] = lista
	}
	for _, g := range lista {
		if g.Numero() == codigo || (g.CodigoExterno() != nil && *g.CodigoExterno() == codigo) {
			return g
		}
	}
	return nil
}

// docente busca por documento institucional o por correo.
func (c *catalogoImportacion) docente(ctx context.Context, ref string) *user.Usuario {
	if u, ok := c.docentes[ref]; ok || c.s.usuarioRepo == nil {
		return u
	}
	u, err := c.s.usuarioRepo.FindByDocumento(ctx, ref)
	if err != nil || u == nil {
		u, _ = c.s.usuarioRepo.FindByCorreo(ctx, ref)
	}
	c.docentes[ref] = u
	return u
}

func (c *catalogoImportacion) aula(ctx context.Context, codigo string) *geo.Espacio {
	if e, ok := c.aulas[codigo]; ok {
		return e
	}
	var e *geo.Espacio
	if c.s.espacioRepo != nil {
		e, _ = c.s.espacioRepo.FindByCodigo(ctx, codigo)
	}
	c.aulas[codigo] = e
	return e
}

// existentes son las asignaciones activas del periodo, para detectar colisiones.
func (c *catalogoImportacion) existentes(ctx context.Context, periodoID string) []domainAca.Asignacion {
	if l, ok := c.asignaciones[periodoID]; ok {
		return l
	}
	l, _ := c.s.asignacionRepo.ListByPeriodoID(ctx, periodoID)
	c.asignaciones[periodoID] = l
	return l
}
