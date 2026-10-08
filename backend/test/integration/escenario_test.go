package integration

import (
	"net/http"
	"time"
)

// escenario es la estructura mínima de una universidad con una clase en curso hoy.
type escenario struct {
	admin, docente                  string // access tokens
	docenteID                       string
	sede, bloque, espacio, espacio2 string
	facultad, programa, asignatura  string
	periodo, grupo, asignacion      string
	dispositivo                     string
}

// Polígono de ~22 m x 22 m en Mocoa; el centro (1.1477, -76.6511) queda dentro.
var poligonoAula = [][2]float64{
	{-76.6512, 1.1478}, {-76.6510, 1.1478}, {-76.6510, 1.1476}, {-76.6512, 1.1476}, {-76.6512, 1.1478},
}

// Polígono vecino, sin solapamiento con el aula principal.
var poligonoAula2 = [][2]float64{
	{-76.6500, 1.1478}, {-76.6498, 1.1478}, {-76.6498, 1.1476}, {-76.6500, 1.1476}, {-76.6500, 1.1478},
}

var bogota = func() *time.Location {
	loc, err := time.LoadLocation("America/Bogota")
	if err != nil {
		return time.FixedZone("COT", -5*3600)
	}
	return loc
}()

// construirEscenario crea sede → espacios → estructura académica → asignación con una franja
// que empezó hace 3 minutos, y genera las sesiones del periodo.
func construirEscenario(e *entorno) *escenario {
	e.t.Helper()
	return construirEscenarioCon(e, nil)
}

// construirEscenarioCon fija además parámetros de la sede antes de generar las sesiones,
// que los congelan (RN-002). El docente acepta el aviso de privacidad vigente, requisito
// para marcar (Ley 1581).
func construirEscenarioCon(e *entorno, parametros map[string]interface{}) *escenario {
	e.t.Helper()
	s := construirEscenarioSinConsentimiento(e, parametros)
	s.aceptarPrivacidad(e)
	return s
}

// aceptarPrivacidad registra la aceptación del docente sobre la versión vigente del aviso.
func (s *escenario) aceptarPrivacidad(e *entorno) {
	e.t.Helper()
	version := e.exigir(http.MethodGet, "/me/consentimiento", nil, s.docente, http.StatusOK)["versionVigente"]
	e.exigir(http.MethodPost, "/me/consentimiento", map[string]interface{}{
		"version": version, "acepta": true, "dispositivoId": s.dispositivo,
	}, s.docente, http.StatusOK)
}

// construirEscenarioSinConsentimiento arma el escenario sin que el docente decida sobre el aviso.
func construirEscenarioSinConsentimiento(e *entorno, parametros map[string]interface{}) *escenario {
	e.t.Helper()
	ahora := time.Now().In(bogota)
	inicio := ahora.Truncate(time.Minute).Add(-3 * time.Minute)
	if inicio.Day() != ahora.Day() || ahora.Hour() >= 23 && ahora.Minute() >= 50 {
		e.t.Skip("la franja de prueba cruzaría la medianoche en America/Bogota")
	}
	fin := inicio.Add(2 * time.Hour)
	if fin.Day() != inicio.Day() {
		fin = time.Date(inicio.Year(), inicio.Month(), inicio.Day(), 23, 59, 0, 0, bogota)
	}

	s := &escenario{admin: e.token(correoAdmin, claveAdmin), dispositivo: "dispositivo-integracion-1"}
	post := func(ruta string, cuerpo map[string]interface{}) string {
		return texto(e.exigir(http.MethodPost, ruta, cuerpo, s.admin, http.StatusCreated)["id"])
	}
	s.sede = post("/sedes", map[string]interface{}{"codigo": "SC", "nombre": "Sede Central", "direccion": "Calle 1"})
	s.bloque = post("/bloques", map[string]interface{}{"sedeId": s.sede, "codigo": "B1", "nombre": "Bloque 1", "pisos": []int{1, 2, 3}})
	s.espacio = post("/espacios", map[string]interface{}{"sedeId": s.sede, "bloqueId": s.bloque, "piso": 3, "codigo": "A-301", "nombre": "Aula 301", "capacidad": 35, "tipo": "AULA"})
	s.espacio2 = post("/espacios", map[string]interface{}{"sedeId": s.sede, "bloqueId": s.bloque, "piso": 3, "codigo": "A-302", "nombre": "Aula 302", "capacidad": 30, "tipo": "AULA"})
	for id, poligono := range map[string][][2]float64{s.espacio: poligonoAula, s.espacio2: poligonoAula2} {
		e.exigir(http.MethodPut, "/espacios/"+id+"/geometria", map[string]interface{}{
			"coordenadas": poligono, "metodoCaptura": "RECORRIDO_PERIMETRAL", "precisionPromedioMetros": 6.8,
		}, s.admin, http.StatusOK)
	}

	s.facultad = post("/facultades", map[string]interface{}{"codigo": "ING", "nombre": "Ingeniería", "sedeId": s.sede})
	s.programa = post("/programas", map[string]interface{}{"codigo": "SIS", "nombre": "Sistemas", "facultadId": s.facultad})
	s.asignatura = post("/asignaturas", map[string]interface{}{"codigo": "MAT1", "nombre": "Cálculo", "programaId": s.programa, "creditos": 3})
	s.periodo = post("/periodos", map[string]interface{}{
		"codigo": "2026-2", "nombre": "Periodo de prueba", "estado": "ACTIVO", "sedeId": s.sede,
		"fechaInicio": ahora.AddDate(0, 0, -30).Format("2006-01-02"),
		"fechaFin":    ahora.AddDate(0, 0, 60).Format("2006-01-02"),
	})
	s.grupo = post("/grupos", map[string]interface{}{"numero": "01", "asignaturaId": s.asignatura, "periodoId": s.periodo, "cupo": 30})

	_, usuarios := e.llamar(http.MethodGet, "/usuarios", nil, s.admin)
	for _, u := range elementos(usuarios) {
		if u["correo"] == correoDocente {
			s.docenteID = texto(u["id"])
		}
	}
	if s.docenteID == "" {
		e.t.Fatalf("no se encontró el docente semilla en GET /usuarios: %v", usuarios)
	}

	asignacion := map[string]interface{}{
		"periodoId": s.periodo, "docenteIds": []string{s.docenteID}, "docenteNombre": "Docente Prueba",
		"grupoId": s.grupo, "asignaturaId": s.asignatura, "facultadId": s.facultad, "espacioId": s.espacio,
		"franja": map[string]interface{}{
			"diaSemana": int(ahora.Weekday()+6)%7 + 1, "horaInicio": inicio.Format("15:04"), "horaFin": fin.Format("15:04"),
		},
		"modalidad": "PRESENCIAL",
	}
	s.asignacion = post("/asignaciones", asignacion)
	// RF-ACA-005: la misma franja con el mismo docente y aula colisiona.
	e.exigir(http.MethodPost, "/asignaciones", asignacion, s.admin, http.StatusConflict)

	// RN-002: la holgura definida en la sede se congela en las sesiones generadas.
	e.exigir(http.MethodPut, "/parametros", map[string]interface{}{
		"ambito": "SEDE", "ambito_id": s.sede, "clave": "holgura_entrada_despues_min", "valor": 20,
	}, s.admin, http.StatusOK)
	for clave, valor := range parametros {
		e.exigir(http.MethodPut, "/parametros", map[string]interface{}{
			"ambito": "SEDE", "ambito_id": s.sede, "clave": clave, "valor": valor,
		}, s.admin, http.StatusOK)
	}
	gen := e.exigir(http.MethodPost, "/periodos/"+s.periodo+"/generar-sesiones", map[string]interface{}{"incluirPasadas": true}, s.admin, http.StatusOK)
	if gen["sesionesGeneradas"].(float64) < 1 {
		e.t.Fatalf("no se generaron sesiones: %v", gen)
	}
	gen2 := e.exigir(http.MethodPost, "/periodos/"+s.periodo+"/generar-sesiones", map[string]interface{}{"incluirPasadas": true}, s.admin, http.StatusOK)
	if gen2["sesionesGeneradas"].(float64) != 0 {
		e.t.Fatalf("la generación debe ser idempotente: %v", gen2)
	}

	s.docente = texto(e.iniciarSesion(correoDocente, claveDocente, s.dispositivo)["accessToken"])
	e.exigir(http.MethodPost, "/auth/devices", map[string]interface{}{
		"instalacionId": s.dispositivo, "modelo": "Pixel", "so": "Android 14", "versionApp": "1.0.0",
	}, s.docente, http.StatusCreated)
	return s
}

// marcaje arma una solicitud de marcaje en la posición dada.
func (s *escenario) marcaje(sesionID string, lat, lon float64, clave string) map[string]interface{} {
	return map[string]interface{}{
		"sesionId": sesionID, "tipo": "ENTRADA", "latitud": lat, "longitud": lon, "precisionMetros": 8.2,
		"timestampDispositivo": time.Now().UTC().Format(time.RFC3339), "dispositivoId": s.dispositivo,
		"versionApp": "1.0.0", "idempotencyKey": clave,
		"integridad": map[string]interface{}{"mockLocation": false, "rooteado": false, "emulador": false, "attestationOk": true},
	}
}
