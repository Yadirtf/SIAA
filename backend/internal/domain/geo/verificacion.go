// Package geo — métodos complementarios de verificación por espacio (RF-GEO-016, riesgo R-01).
// Desambiguan pisos cuando el GPS no distingue un aula de la que tiene encima o debajo.
package geo

import (
	"regexp"
	"strings"

	"github.com/siaa/backend/internal/domain/shared"
)

// Métodos de verificación complementaria aceptados.
const (
	MetodoVerificacionWifi = "WIFI"
	MetodoVerificacionBLE  = "BLE"
	MetodoVerificacionQR   = "QR"
)

var patronBSSID = regexp.MustCompile(`^[0-9a-f]{2}(:[0-9a-f]{2}){5}$`)

// VerificacionEspacio agrupa los valores que el dispositivo debe observar dentro del aula.
type VerificacionEspacio struct {
	WifiBssids []string `json:"wifiBssids"`
	BleUUID    string   `json:"bleUuid,omitempty"`
	QrCodigo   string   `json:"qrCodigo,omitempty"`
}

// NormalizarValorVerificacion lleva un valor observado a la forma canónica del método,
// para que "A4-2B-8C-11-02-9F" y "a4:2b:8c:11:02:9f" coincidan. En BLE se descartan los
// guiones: un UUID 8-4-4-4-12 y su forma de 32 hexadecimales sin guiones son el mismo beacon.
func NormalizarValorVerificacion(metodo, valor string) string {
	valor = strings.TrimSpace(valor)
	switch strings.ToUpper(strings.TrimSpace(metodo)) {
	case MetodoVerificacionWifi:
		return strings.ToLower(strings.ReplaceAll(valor, "-", ":"))
	case MetodoVerificacionBLE:
		return strings.ToLower(strings.ReplaceAll(valor, "-", ""))
	case MetodoVerificacionQR:
		return strings.ToUpper(valor)
	}
	return valor
}

// ClaveVerificacion combina método y valor normalizado; así un QR nunca coincide con un BSSID.
func ClaveVerificacion(metodo, valor string) string {
	m := strings.ToUpper(strings.TrimSpace(metodo))
	return m + "|" + NormalizarValorVerificacion(m, valor)
}

// Normalizar deja los valores en forma canónica y descarta vacíos y duplicados.
func (v *VerificacionEspacio) Normalizar() {
	vistos := map[string]bool{}
	bssids := make([]string, 0, len(v.WifiBssids))
	for _, b := range v.WifiBssids {
		n := NormalizarValorVerificacion(MetodoVerificacionWifi, b)
		if n != "" && !vistos[n] {
			vistos[n] = true
			bssids = append(bssids, n)
		}
	}
	v.WifiBssids = bssids
	// El UUID se guarda en minúsculas conservando sus guiones para mostrarlo legible; la
	// comparación (ClaveVerificacion) sí los descarta.
	v.BleUUID = strings.ToLower(strings.TrimSpace(v.BleUUID))
	v.QrCodigo = NormalizarValorVerificacion(MetodoVerificacionQR, v.QrCodigo)
}

// Validar exige BSSIDs con formato MAC y un código QR de al menos 6 caracteres.
func (v *VerificacionEspacio) Validar() error {
	var campos []shared.FieldError
	for _, b := range v.WifiBssids {
		if !patronBSSID.MatchString(b) {
			campos = append(campos, shared.FieldError{Campo: "wifiBssids", Error: "BSSID inválido: " + b})
		}
	}
	if v.QrCodigo != "" && len(v.QrCodigo) < 6 {
		campos = append(campos, shared.FieldError{Campo: "qrCodigo", Error: "El código QR debe tener al menos 6 caracteres"})
	}
	if len(campos) > 0 {
		return shared.NewValidationError("Verificación complementaria inválida", campos...)
	}
	return nil
}

// Claves devuelve los valores aceptados en forma de ClaveVerificacion.
func (v *VerificacionEspacio) Claves() []string {
	if v == nil {
		return nil
	}
	claves := make([]string, 0, len(v.WifiBssids)+2)
	for _, b := range v.WifiBssids {
		claves = append(claves, ClaveVerificacion(MetodoVerificacionWifi, b))
	}
	if v.BleUUID != "" {
		claves = append(claves, ClaveVerificacion(MetodoVerificacionBLE, v.BleUUID))
	}
	if v.QrCodigo != "" {
		claves = append(claves, ClaveVerificacion(MetodoVerificacionQR, v.QrCodigo))
	}
	return claves
}

// Metodos indica qué métodos tiene configurados el espacio, sin revelar los valores.
func (v *VerificacionEspacio) Metodos() []string {
	if v == nil {
		return nil
	}
	var metodos []string
	if len(v.WifiBssids) > 0 {
		metodos = append(metodos, MetodoVerificacionWifi)
	}
	if v.BleUUID != "" {
		metodos = append(metodos, MetodoVerificacionBLE)
	}
	if v.QrCodigo != "" {
		metodos = append(metodos, MetodoVerificacionQR)
	}
	return metodos
}
