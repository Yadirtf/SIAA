package academico

// ConUbicacionAcademica registra la sede y la facultad de la sesión. Se fijan al generarla
// (desde el aula y la asignación) para que los listados filtren por ámbito sin cruces
// adicionales (RF-ROL-003).
func (s *Sesion) ConUbicacionAcademica(sedeID, facultadID string) *Sesion {
	s.sedeID = sedeID
	s.facultadID = facultadID
	return s
}

// SedeID es la sede donde se dicta la sesión.
func (s *Sesion) SedeID() string { return s.sedeID }

// FacultadID es la facultad responsable de la asignación de la sesión.
func (s *Sesion) FacultadID() string { return s.facultadID }
