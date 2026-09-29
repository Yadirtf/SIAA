package usuarios

import (
	"context"
	"encoding/csv"
	"errors"
	"io"
	"strconv"
	"strings"

	"github.com/siaa/backend/internal/domain/rbac"
	"github.com/siaa/backend/internal/domain/shared"
)

// maxFilasImportacion limita el tamaño de un lote para acotar memoria y tiempo de respuesta.
const maxFilasImportacion = 5000

// FilaImportacion es el resultado de validar (o crear) una fila del CSV.
type FilaImportacion struct {
	Fila    int    `json:"fila"`
	Correo  string `json:"correo"`
	Nombre  string `json:"nombre"`
	Valida  bool   `json:"valida"`
	Creado  bool   `json:"creado"`
	Error   string `json:"error,omitempty"`
	Usuario string `json:"usuarioId,omitempty"`
}

// ResultadoImportacion resume el lote: en vista previa nada se crea.
type ResultadoImportacion struct {
	Confirmado bool              `json:"confirmado"`
	Total      int               `json:"total"`
	Validas    int               `json:"validas"`
	Creados    int               `json:"creados"`
	Filas      []FilaImportacion `json:"filas"`
}

// ImportarCSV procesa un CSV con encabezados correo, nombre, apellido, documento y, opcionales,
// roles (separados por "|", DOCENTE por defecto) y ambitos ("FACULTAD:id|SEDE:id").
// Con confirmar=false solo valida; con true crea las filas válidas e invita por correo.
func (s *Service) ImportarCSV(ctx context.Context, actor Actor, r io.Reader, confirmar bool) (*ResultadoImportacion, error) {
	lector := csv.NewReader(r)
	lector.TrimLeadingSpace = true
	lector.FieldsPerRecord = -1
	enc, err := lector.Read()
	if err != nil {
		return nil, shared.NewValidationError("No se pudo leer el encabezado del CSV")
	}
	col := indiceColumnas(enc)
	for _, req := range []string{"correo", "nombre", "apellido"} {
		if _, ok := col[req]; !ok {
			return nil, shared.NewValidationError("Falta la columna obligatoria: " + req)
		}
	}
	res := &ResultadoImportacion{Confirmado: confirmar, Filas: []FilaImportacion{}}
	vistos := map[string]int{}
	for n := 2; ; n++ {
		reg, err := lector.Read()
		if errors.Is(err, io.EOF) {
			break
		}
		if res.Total >= maxFilasImportacion {
			return nil, shared.NewValidationError("El archivo supera el máximo de 5000 filas")
		}
		res.Total++
		fila := FilaImportacion{Fila: n}
		if err != nil {
			fila.Error = "Fila mal formada"
			res.Filas = append(res.Filas, fila)
			continue
		}
		cmd := comandoDeFila(reg, col)
		fila.Correo, fila.Nombre = strings.ToLower(cmd.Correo), strings.TrimSpace(cmd.Nombre+" "+cmd.Apellido)
		if previa, dup := vistos[fila.Correo]; dup {
			fila.Error = "Correo repetido en la fila " + strconv.Itoa(previa)
		} else if _, err := s.prepararAlta(ctx, actor, cmd); err != nil {
			fila.Error = mensaje(err)
		} else {
			vistos[fila.Correo] = n
			fila.Valida = true
			res.Validas++
			if confirmar {
				if cr, err := s.Crear(ctx, actor, cmd); err != nil {
					fila.Valida, fila.Error = false, mensaje(err)
					res.Validas--
				} else {
					fila.Creado, fila.Usuario = true, cr.Usuario.ID
					res.Creados++
				}
			}
		}
		res.Filas = append(res.Filas, fila)
	}
	return res, nil
}

func indiceColumnas(enc []string) map[string]int {
	col := make(map[string]int, len(enc))
	for i, h := range enc {
		col[strings.ToLower(strings.TrimSpace(strings.TrimPrefix(h, "\uFEFF")))] = i
	}
	return col
}

func comandoDeFila(reg []string, col map[string]int) CrearCmd {
	campo := func(nombre string) string {
		if i, ok := col[nombre]; ok && i < len(reg) {
			return strings.TrimSpace(reg[i])
		}
		return ""
	}
	cmd := CrearCmd{Correo: campo("correo"), Nombre: campo("nombre"), Apellido: campo("apellido"), Documento: campo("documento")}
	roles := campo("roles")
	if roles == "" {
		roles = string(rbac.RolDocente)
	}
	for _, r := range strings.Split(roles, "|") {
		cmd.Roles = append(cmd.Roles, RolCmd{Nombre: r})
	}
	for _, a := range strings.Split(campo("ambitos"), "|") {
		if tipo, id, ok := strings.Cut(strings.TrimSpace(a), ":"); ok {
			cmd.Ambitos = append(cmd.Ambitos, rbac.Scope{Tipo: rbac.ScopeType(tipo), ID: id})
		}
	}
	return cmd
}

func mensaje(err error) string {
	if de, ok := shared.AsDomainError(err); ok {
		return de.Message
	}
	return "Error interno al procesar la fila"
}
