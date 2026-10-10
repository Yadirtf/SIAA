package geo

import "testing"

func TestVerificacionEspacio_NormalizaYValida(t *testing.T) {
	v := VerificacionEspacio{WifiBssids: []string{" A4-2B-8C-11-02-9F", "a4:2b:8c:11:02:9f", ""}, BleUUID: " ABC ", QrCodigo: "siaa-a301"}
	v.Normalizar()
	if len(v.WifiBssids) != 1 || v.WifiBssids[0] != "a4:2b:8c:11:02:9f" || v.BleUUID != "abc" || v.QrCodigo != "SIAA-A301" {
		t.Fatalf("normalización inesperada: %+v", v)
	}
	if err := v.Validar(); err != nil {
		t.Fatalf("valores válidos rechazados: %v", err)
	}
	if got := v.Metodos(); len(got) != 3 {
		t.Fatalf("métodos: %v", got)
	}
	claves := v.Claves()
	if len(claves) != 3 || claves[0] != ClaveVerificacion("wifi", "A4:2B:8C:11:02:9F") {
		t.Fatalf("claves: %v", claves)
	}
	if ClaveVerificacion(MetodoVerificacionQR, "SIAA-A301") == ClaveVerificacion(MetodoVerificacionWifi, "SIAA-A301") {
		t.Fatal("un mismo valor en métodos distintos no debe coincidir")
	}

	malo := VerificacionEspacio{WifiBssids: []string{"zz:zz"}, QrCodigo: "ab"}
	malo.Normalizar()
	if err := malo.Validar(); err == nil {
		t.Fatal("un BSSID inválido y un QR corto deben rechazarse")
	}
	var nulo *VerificacionEspacio
	if nulo.Claves() != nil || nulo.Metodos() != nil {
		t.Fatal("un espacio sin verificación no aporta claves ni métodos")
	}
	if NormalizarValorVerificacion("OTRO", " x ") != "x" {
		t.Fatal("un método desconocido solo recorta espacios")
	}
}

func TestVerificacionBLE_IgnoraGuionesYMayusculas(t *testing.T) {
	const conGuiones = "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"
	const sinGuiones = "e2c56db5dffb48d2b060d0f5a71096e0"
	if got := NormalizarValorVerificacion(MetodoVerificacionBLE, " "+conGuiones+" "); got != sinGuiones {
		t.Fatalf("normalización BLE: %q", got)
	}
	v := VerificacionEspacio{BleUUID: conGuiones}
	v.Normalizar()
	if v.BleUUID != "e2c56db5-dffb-48d2-b060-d0f5a71096e0" {
		t.Fatalf("el UUID registrado debe conservarse legible: %q", v.BleUUID)
	}
	claves := v.Claves()
	if len(claves) != 1 || claves[0] != ClaveVerificacion("ble", sinGuiones) || claves[0] != ClaveVerificacion("BLE", conGuiones) {
		t.Fatalf("registrado con guiones y observado sin ellos deben coincidir: %v", claves)
	}
	if ClaveVerificacion(MetodoVerificacionWifi, "a4-2b-8c-11-02-9f") == ClaveVerificacion(MetodoVerificacionWifi, "a42b8c11029f") {
		t.Fatal("en WIFI los guiones siguen siendo separadores, no se eliminan")
	}
}
