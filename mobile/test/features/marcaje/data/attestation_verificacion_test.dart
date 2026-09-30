// attestation_verificacion_test.dart — Hash de attestation y selección de verificación complementaria
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/marcaje/data/services/attestation_service.dart';
import 'package:siaa_mobile/features/marcaje/data/services/selector_verificacion.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/sesion_activa_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AttestationService', () {
    test('hashSolicitud coincide con HashSolicitud del backend', () {
      expect(
        AttestationService.hashSolicitud('s1', 'ENTRADA', 'k1'),
        'b1f90c33b6bf79df031004f3f31f31c56d7fde341bbbcec15b6d5306fadbf9ca',
      );
    });

    test('sin proyecto cloud o fuera de Android no pide token', () async {
      final sinProyecto =
          AttestationService(proyectoCloud: '', plataformaSoportada: true);
      expect(
          await sinProyecto.obtenerToken(
              sesionId: 's1', tipo: 'ENTRADA', idempotencyKey: 'k1'),
          isNull);
      final ios =
          AttestationService(proyectoCloud: '123', plataformaSoportada: false);
      expect(
          await ios.obtenerToken(
              sesionId: 's1', tipo: 'ENTRADA', idempotencyKey: 'k1'),
          isNull);
    });

    test('envía el requestHash por el canal y devuelve null ante error',
        () async {
      const canal = MethodChannel('siaa/integridad-test');
      final llamadas = <MethodCall>[];
      var fallar = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (call) async {
        llamadas.add(call);
        if (fallar) throw PlatformException(code: 'SOLICITAR');
        return 'tok';
      });
      final svc = AttestationService(
          canal: canal, proyectoCloud: '123456', plataformaSoportada: true);

      expect(
          await svc.obtenerToken(
              sesionId: 's1', tipo: 'ENTRADA', idempotencyKey: 'k1'),
          'tok');
      expect(llamadas.single.arguments, {
        'numeroProyecto': 123456,
        'requestHash':
            'b1f90c33b6bf79df031004f3f31f31c56d7fde341bbbcec15b6d5306fadbf9ca',
      });
      fallar = true;
      expect(
          await svc.obtenerToken(
              sesionId: 's1', tipo: 'ENTRADA', idempotencyKey: 'k1'),
          isNull);
    });
  });

  group('SelectorVerificacion', () {
    test('no envía nada si no es exigida', () {
      expect(
          SelectorVerificacion.seleccionar(
              exigida: false, metodos: ['WIFI'], bssid: 'aa:bb:cc:dd:ee:ff'),
          isNull);
    });

    test('prefiere WIFI con BSSID válido y no pide QR', () {
      final v = SelectorVerificacion.seleccionar(
          exigida: true, metodos: ['QR', 'WIFI'], bssid: 'AA:BB:CC:DD:EE:FF');
      expect(v?.metodo, 'WIFI');
      expect(v?.valor, 'AA:BB:CC:DD:EE:FF');
      expect(
          SelectorVerificacion.requiereCodigoQr(
              exigida: true,
              metodos: ['QR', 'WIFI'],
              bssid: 'AA:BB:CC:DD:EE:FF'),
          isFalse);
    });

    test('sin BSSID legible cae a QR si el aula lo admite', () {
      const sinPermiso = '02:00:00:00:00:00';
      expect(
          SelectorVerificacion.requiereCodigoQr(
              exigida: true, metodos: ['WIFI', 'QR'], bssid: sinPermiso),
          isTrue);
      final v = SelectorVerificacion.seleccionar(
          exigida: true,
          metodos: ['WIFI', 'QR'],
          bssid: sinPermiso,
          codigoQr: ' aula-301 ');
      expect(v?.metodo, 'QR');
      expect(v?.valor, 'aula-301');
    });

    test('solo WIFI sin BSSID o solo BLE: no envía testigo', () {
      expect(SelectorVerificacion.seleccionar(exigida: true, metodos: ['WIFI']),
          isNull);
      expect(
          SelectorVerificacion.requiereCodigoQr(
              exigida: true, metodos: ['WIFI']),
          isFalse);
      expect(
          SelectorVerificacion.seleccionar(
              exigida: true, metodos: ['BLE'], codigoQr: 'x'),
          isNull);
    });
  });

  test('SesionActivaModel lee exigirAttestation y métodos de verificación', () {
    final m = SesionActivaModel.fromDetalleJson({
      'sesion': {'id': 's1'},
      'ventana': {'estado': 'ABIERTA'},
      'parametros': {'exigirAttestation': true},
      'verificacionComplementariaExigida': true,
      'metodosVerificacion': ['wifi', 'QR'],
      'marcajeExistente': {'tipo': 'ENTRADA', 'resultado': 'TARDANZA'},
    });
    expect(m.exigirAttestation, isTrue);
    expect(m.verificacionComplementariaExigida, isTrue);
    expect(m.metodosVerificacion, ['WIFI', 'QR']);
    expect(m.tieneMarcajeEntrada, isTrue);
  });
}
