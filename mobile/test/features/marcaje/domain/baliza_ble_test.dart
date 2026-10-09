// baliza_ble_test.dart — UUID de baliza BLE y código QR del aula (US-GEO-13)
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/marcaje/data/services/baliza_ble_service.dart';
import 'package:siaa_mobile/features/marcaje/data/services/escaner_ble.dart';
import 'package:siaa_mobile/features/marcaje/data/services/selector_verificacion.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/lectura_baliza.dart';
import 'package:siaa_mobile/features/marcaje/domain/services/codigo_qr_aula.dart';
import 'package:siaa_mobile/features/marcaje/domain/services/selector_baliza.dart';
import 'package:siaa_mobile/features/marcaje/presentation/helpers/aviso_verificacion.dart';

const _uuidBytes = [
  0xE2, 0xC5, 0x6D, 0xB5, 0xDF, 0xFB, 0x48, 0xD2, //
  0xB0, 0x60, 0xD0, 0xF5, 0xA7, 0x10, 0x96, 0xE0,
];
const _uuid = 'e2c56db5-dffb-48d2-b060-d0f5a71096e0';

/// iBeacon: 0x02 0x15, UUID (16), major (2), minor (2), potencia (1).
Map<int, List<int>> _ibeacon([List<int> uuid = _uuidBytes]) => {
      0x004C: [0x02, 0x15, ...uuid, 0x00, 0x01, 0x00, 0x02, 0xC5],
    };

class _EscanerFijo implements EscanerBle {
  final List<AnuncioBle> anuncios;
  final FallaEscanerBle? falla;
  Duration? duracionPedida;

  _EscanerFijo(this.anuncios, {this.falla});

  @override
  Future<List<AnuncioBle>> escanear(Duration duracion) async {
    duracionPedida = duracion;
    if (falla != null) throw falla!;
    return anuncios;
  }
}

void main() {
  group('SelectorBaliza', () {
    test('extrae el UUID de proximidad de un iBeacon', () {
      expect(SelectorBaliza.uuidIBeacon(_ibeacon()), _uuid);
    });

    test('ignora datos de Apple que no son iBeacon', () {
      expect(
          SelectorBaliza.uuidIBeacon({
            0x004C: [0x10, 0x05, 0x01]
          }),
          isNull);
      expect(SelectorBaliza.uuidIBeacon({0x0059: _ibeacon()[0x004C]!}), isNull);
    });

    test('elige el iBeacon de mejor señal', () {
      final otro = List<int>.filled(16, 0xAA);
      final uuid = SelectorBaliza.elegir([
        AnuncioBle(datosFabricante: _ibeacon(otro), rssi: -90),
        AnuncioBle(datosFabricante: _ibeacon(), rssi: -55),
      ]);
      expect(uuid, _uuid);
    });

    test('sin iBeacon usa un UUID de servicio propio, no los estándar', () {
      expect(
          SelectorBaliza.elegir(const [
            AnuncioBle(
                uuidsServicio: ['0000180f-0000-1000-8000-00805f9b34fb'],
                rssi: -40),
          ]),
          isNull);
      expect(
          SelectorBaliza.elegir(const [
            AnuncioBle(
                uuidsServicio: ['E2C56DB5-DFFB-48D2-B060-D0F5A71096E0'],
                rssi: -60),
          ]),
          _uuid);
    });

    test('el iBeacon tiene prioridad sobre un servicio con más señal', () {
      final uuid = SelectorBaliza.elegir([
        const AnuncioBle(
            uuidsServicio: ['11111111-2222-3333-4444-555555555555'], rssi: -30),
        AnuncioBle(datosFabricante: _ibeacon(), rssi: -80),
      ]);
      expect(uuid, _uuid);
    });
  });

  group('BalizaBleService', () {
    test('escanea 8 s y devuelve el UUID encontrado', () async {
      final escaner =
          _EscanerFijo([AnuncioBle(datosFabricante: _ibeacon(), rssi: -60)]);
      final r = await BalizaBleService(escaner: escaner).buscar();
      expect(r, const LecturaBaliza.encontrada(_uuid));
      expect(escaner.duracionPedida, const Duration(seconds: 8));
    });

    test('sin balizas informa "no encontrada"', () async {
      final r =
          await BalizaBleService(escaner: _EscanerFijo(const [])).buscar();
      expect(r.motivo, MotivoSinBaliza.noEncontrada);
      expect(r.exitosa, isFalse);
    });

    test('traslada el motivo de la falla del escáner', () async {
      final r = await BalizaBleService(
        escaner: _EscanerFijo(const [],
            falla: const FallaEscanerBle(MotivoSinBaliza.sinPermiso)),
      ).buscar();
      expect(r.motivo, MotivoSinBaliza.sinPermiso);
    });
  });

  group('SelectorVerificacion con BLE', () {
    test('WIFI > BLE > QR', () {
      expect(
          SelectorVerificacion.seleccionar(
                  exigida: true,
                  metodos: ['WIFI', 'BLE', 'QR'],
                  bssid: 'aa:bb:cc:dd:ee:ff',
                  uuidBle: _uuid,
                  codigoQr: 'X')
              ?.metodo,
          'WIFI');
      final v = SelectorVerificacion.seleccionar(
          exigida: true,
          metodos: ['WIFI', 'BLE', 'QR'],
          uuidBle: _uuid.toUpperCase(),
          codigoQr: 'X');
      expect(v?.metodo, 'BLE');
      expect(v?.valor, _uuid);
    });

    test('no se busca baliza si el WiFi ya resolvió', () {
      expect(
          SelectorVerificacion.requiereBle(
              exigida: true,
              metodos: ['WIFI', 'BLE'],
              bssid: 'aa:bb:cc:dd:ee:ff'),
          isFalse);
      expect(
          SelectorVerificacion.requiereBle(
              exigida: true, metodos: ['WIFI', 'BLE']),
          isTrue);
      expect(
          SelectorVerificacion.requiereCodigoQr(
              exigida: true, metodos: ['BLE', 'QR'], uuidBle: _uuid),
          isFalse);
    });
  });

  group('CodigoQrAula', () {
    test('usa el texto del QR recortado', () {
      expect(CodigoQrAula.extraer('  AULA-301-QR \n'), 'AULA-301-QR');
      expect(CodigoQrAula.extraer('   '), isNull);
      expect(CodigoQrAula.extraer(null), isNull);
    });

    test('si el QR es un enlace toma el parámetro codigo', () {
      expect(CodigoQrAula.extraer('https://siaa.edu.co/aula?codigo=B4-201-XQ'),
          'B4-201-XQ');
      expect(CodigoQrAula.extraer('https://siaa.edu.co/aula'),
          'https://siaa.edu.co/aula');
    });
  });

  test('AvisoVerificacion explica cada motivo BLE', () {
    for (final m in MotivoSinBaliza.values) {
      expect(AvisoVerificacion.baliza(m), isNotEmpty);
    }
    expect(AvisoVerificacion.sinTestigo(['BLE'], MotivoSinBaliza.sinPermiso),
        contains('permiso de Bluetooth'));
    expect(AvisoVerificacion.sinTestigo(['WIFI', 'BLE'], null),
        allOf(contains('WiFi'), contains('baliza')));
  });
}
