package privacidad

// DecisionSupresion indica qué ocurre con una categoría de datos ante la supresión (AC-03).
type DecisionSupresion string

const (
	SeElimina  DecisionSupresion = "ELIMINABLE"
	SeConserva DecisionSupresion = "CONSERVAR"
)

// Categorías de datos del titular que trata SIAA.
const (
	CategoriaIdentificacion  = "IDENTIFICACION"
	CategoriaUbicaciones     = "UBICACIONES_MARCAJE"
	CategoriaAsistencia      = "REGISTROS_ASISTENCIA"
	CategoriaJustificaciones = "JUSTIFICACIONES"
	CategoriaConsentimientos = "CONSENTIMIENTOS"
	CategoriaAuditoria       = "BITACORA_AUDITORIA"
	CategoriaAvisos          = "AVISOS_Y_TOKENS"
	CategoriaDispositivos    = "DISPOSITIVOS"
)

// ElementoSupresion explica, para una categoría de datos, si puede eliminarse y por qué.
type ElementoSupresion struct {
	Categoria   string            `json:"categoria" bson:"categoria"`
	Descripcion string            `json:"descripcion" bson:"descripcion"`
	Decision    DecisionSupresion `json:"decision" bson:"decision"`
	Fundamento  string            `json:"fundamento" bson:"fundamento"`
}

// fundamentoDeberLegal es la excepción general: la supresión no procede cuando el titular tiene
// un deber legal o contractual de permanecer en la base de datos.
const fundamentoDeberLegal = "Decreto 1377 de 2013, art. 9 (Decreto 1074 de 2015, art. 2.2.2.25.2.8): la supresión no procede mientras exista un deber legal o contractual de permanecer en la base de datos."

// EvaluarSupresion informa qué datos del titular pueden eliminarse y cuáles deben conservarse,
// con su fundamento (US-LEG-02 AC-03). bajoInvestigacion indica que hay una investigación en
// curso sobre sus registros (US-AUD-04), que impide borrar sus ubicaciones.
func EvaluarSupresion(bajoInvestigacion bool) []ElementoSupresion {
	ubicaciones := ElementoSupresion{
		Categoria:   CategoriaUbicaciones,
		Descripcion: "Coordenadas GPS tomadas en cada marcaje.",
		Decision:    SeElimina,
		Fundamento:  "Ley 1581 de 2012, art. 4 (principio de finalidad) y art. 8 lit. e: cumplida la verificación del marcaje, la ubicación se anonimiza; se conservan solo el resultado y la distancia al aula.",
	}
	if bajoInvestigacion {
		ubicaciones.Decision = SeConserva
		ubicaciones.Fundamento = "Hay una investigación en curso sobre sus registros: las ubicaciones se conservan como prueba hasta que se cierre (Ley 1581 de 2012, art. 10 lit. b; Decreto 1377 de 2013, art. 11)."
	}
	return []ElementoSupresion{
		ubicaciones,
		{
			Categoria: CategoriaAvisos, Decision: SeElimina,
			Descripcion: "Tokens de notificaciones push y preferencias de avisos.",
			Fundamento:  "Ley 1581 de 2012, art. 8 lit. e: no existe deber legal de conservarlos; se eliminan al atender la solicitud.",
		},
		{
			Categoria: CategoriaIdentificacion, Decision: SeConserva,
			Descripcion: "Nombre, documento, correo institucional, roles y ámbitos de la cuenta.",
			Fundamento:  fundamentoDeberLegal + " Se conservan mientras dure la vinculación laboral o académica con la institución.",
		},
		{
			Categoria: CategoriaAsistencia, Decision: SeConserva,
			Descripcion: "Registros de asistencia (resultado, hora, sesión) sin coordenadas.",
			Fundamento:  fundamentoDeberLegal + " Son soporte del cumplimiento de la jornada y de las actuaciones académicas y administrativas (Ley 594 de 2000, tablas de retención documental).",
		},
		{
			Categoria: CategoriaJustificaciones, Decision: SeConserva,
			Descripcion: "Justificaciones radicadas, sus soportes y la decisión del revisor.",
			Fundamento:  "Soportan decisiones administrativas sobre su asistencia (Ley 594 de 2000; Decreto 1377 de 2013, art. 9).",
		},
		{
			Categoria: CategoriaConsentimientos, Decision: SeConserva,
			Descripcion: "Historial de aceptación o rechazo del aviso de privacidad.",
			Fundamento:  "Ley 1581 de 2012, art. 17 lit. b: el responsable debe conservar prueba de la autorización otorgada por el titular.",
		},
		{
			Categoria: CategoriaAuditoria, Decision: SeConserva,
			Descripcion: "Bitácora de auditoría de las operaciones sobre sus datos.",
			Fundamento:  "Ley 1581 de 2012, art. 17 lit. d y art. 19: la trazabilidad de los tratamientos es requisito de seguridad y prueba ante la autoridad de control.",
		},
		{
			Categoria: CategoriaDispositivos, Decision: SeConserva,
			Descripcion: "Dispositivos vinculados (modelo, sistema operativo, identificador de instalación).",
			Fundamento:  "Identifican el origen de los marcajes conservados; se pueden desvincular desde Perfil y quedan sin uso (Decreto 1377 de 2013, art. 9).",
		},
	}
}

// PlazoDerecho describe el plazo legal de un tipo de solicitud (AC-04).
type PlazoDerecho struct {
	Tipo              string `json:"tipo"`
	Descripcion       string `json:"descripcion"`
	DiasHabiles       int    `json:"diasHabiles"`
	ProrrogaDias      int    `json:"prorrogaDiasHabiles"`
	FundamentoLegal   string `json:"fundamentoLegal"`
	CanalEnAplicacion string `json:"canalEnAplicacion"`
}

// CanalDerechos es el canal publicado para ejercer los derechos del titular (AC-04).
type CanalDerechos struct {
	Institucion string         `json:"institucion"`
	Contacto    string         `json:"contacto"`
	Autoridad   string         `json:"autoridad"`
	Plazos      []PlazoDerecho `json:"plazos"`
}

// NuevoCanalDerechos arma el canal con los plazos legales vigentes.
func NuevoCanalDerechos(institucion, contacto string) CanalDerechos {
	return CanalDerechos{
		Institucion: institucion, Contacto: contacto,
		Autoridad: "Superintendencia de Industria y Comercio (quejas tras agotar el trámite ante la institución, Ley 1581 de 2012, art. 16).",
		Plazos: []PlazoDerecho{
			{Tipo: "CONSULTA", Descripcion: "Conocer sus datos y obtener una copia", DiasHabiles: DiasHabilesConsulta, ProrrogaDias: DiasHabilesProrrogaConsulta,
				FundamentoLegal: "Ley 1581 de 2012, art. 14", CanalEnAplicacion: "Descarga inmediata desde Privacidad y datos"},
			{Tipo: string(SolicitudRectificacion), Descripcion: "Actualizar o rectificar datos inexactos", DiasHabiles: DiasHabilesReclamo, ProrrogaDias: DiasHabilesProrrogaReclamo,
				FundamentoLegal: "Ley 1581 de 2012, art. 15", CanalEnAplicacion: "Solicitud de rectificación"},
			{Tipo: string(SolicitudSupresion), Descripcion: "Suprimir datos o revocar la autorización", DiasHabiles: DiasHabilesReclamo, ProrrogaDias: DiasHabilesProrrogaReclamo,
				FundamentoLegal: "Ley 1581 de 2012, art. 15; Decreto 1377 de 2013, art. 9", CanalEnAplicacion: "Solicitud de supresión"},
		},
	}
}
