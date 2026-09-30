package unit

import (
	"context"
	"errors"
	"testing"
	"time"

	domainMarcaje "github.com/siaa/backend/internal/domain/marcaje"
	usecaseMarcaje "github.com/siaa/backend/internal/usecase/marcaje"
)

// verificadorFalso acepta solo el token "valido" emitido para el hash esperado.
type verificadorFalso struct{ hashRecibido string }

func (v *verificadorFalso) Verificar(_ context.Context, token, hash string) error {
	v.hashRecibido = hash
	if token != "valido" {
		return errors.New("token inválido")
	}
	return nil
}

func solicitudAttestation(clave string, integridad domainMarcaje.IntegridadDispositivo) domainMarcaje.SolicitudMarcaje {
	return domainMarcaje.SolicitudMarcaje{
		SesionID: "ses-attest", UsuarioID: "doc-1", RolMarcaje: domainMarcaje.RolDocente,
		Tipo: domainMarcaje.TipoEntrada, Latitud: 1.1477, Longitud: -76.6511, PrecisionMetros: 8,
		DispositivoID: "disp-1", IdempotencyKey: clave, Integridad: integridad,
	}
}

// La bandera attestationOk del cliente se ignora: solo cuenta la verificación del servidor.
func TestAttestation_SoloCuentaElVeredictoDelServidor(t *testing.T) {
	ahora := time.Date(2026, 9, 30, 8, 0, 0, 0, time.UTC)
	nuevoUC := func() *usecaseMarcaje.CrearMarcajeUseCase {
		return usecaseMarcaje.NewCrearMarcajeUseCase(newFakeMarcajeRepo(), &fakeSesionRepo{}, &fakeEspacioRepo{}, &fakeDispositivoRepo{}, &fakeAuditoriaRepo{}, nil)
	}

	_, m, err := nuevoUC().Ejecutar(context.Background(), solicitudAttestation("k1", domainMarcaje.IntegridadDispositivo{AttestationOk: true}), ahora)
	if err != nil || m == nil || m.Dispositivo.AttestationOk {
		t.Fatalf("sin verificador, la bandera del cliente no debe aceptarse: %+v, %v", m, err)
	}

	v := &verificadorFalso{}
	uc := nuevoUC().WithAttestation(v)
	_, m, _ = uc.Ejecutar(context.Background(), solicitudAttestation("k2", domainMarcaje.IntegridadDispositivo{AttestationToken: "valido"}), ahora)
	if m == nil || !m.Dispositivo.AttestationOk {
		t.Fatalf("un token verificado debe marcar la attestation como válida: %+v", m)
	}
	if v.hashRecibido != usecaseMarcaje.HashSolicitud("ses-attest", domainMarcaje.TipoEntrada, "k2") {
		t.Fatalf("el token debe verificarse contra el hash de esta solicitud: %s", v.hashRecibido)
	}

	_, m, _ = nuevoUC().WithAttestation(v).Ejecutar(context.Background(), solicitudAttestation("k3", domainMarcaje.IntegridadDispositivo{AttestationOk: true, AttestationToken: "falso"}), ahora)
	if m == nil || m.Dispositivo.AttestationOk {
		t.Fatalf("un token rechazado no debe aceptarse aunque el cliente diga lo contrario: %+v", m)
	}
}

func TestHashSolicitud_DistingueIntentos(t *testing.T) {
	a := usecaseMarcaje.HashSolicitud("s1", domainMarcaje.TipoEntrada, "k1")
	if len(a) != 64 || a == usecaseMarcaje.HashSolicitud("s1", domainMarcaje.TipoSalida, "k1") || a == usecaseMarcaje.HashSolicitud("s1", domainMarcaje.TipoEntrada, "k2") {
		t.Fatalf("el hash debe ser SHA-256 hex y cambiar con el tipo y el intento: %s", a)
	}
}
