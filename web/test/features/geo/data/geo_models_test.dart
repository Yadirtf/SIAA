import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/core/network/errores_campo.dart';
import 'package:siaa_web/features/geo/data/models/geo_models.dart';
import 'package:siaa_web/features/geo/domain/codigo_qr.dart';

Map<String, dynamic> espacioJson({Map<String, dynamic>? verificacion}) => {
  'id': 'e1',
  'sedeId': 's1',
  'codigo': 'AUL-101',
  'nombre': 'Aula 101',
  'capacidad': 30,
  'tipo': 'AULA',
  'estado': 'DISPONIBLE',
  'activo': true,
  'verificacionComplementaria': ?verificacion,
};

void main() {
  group('EspacioModel.verificacionComplementaria', () {
    test('se lee cuando el backend la incluye', () {
      final e = EspacioModel.fromJson(
        espacioJson(
          verificacion: {
            'wifiBssids': ['a4:2b:8c:11:02:9f'],
            'bleUuid': 'f7826da6-4fa2-4e98-8024-bc5b71e0893e',
            'qrCodigo': 'SIAA-AUL-101-ABC123',
          },
        ),
      );
      final v = e.verificacionComplementaria!;
      expect(v.wifiBssids, ['a4:2b:8c:11:02:9f']);
      expect(v.bleUuid, 'f7826da6-4fa2-4e98-8024-bc5b71e0893e');
      expect(v.qrCodigo, 'SIAA-AUL-101-ABC123');
      expect(v.metodos, ['WIFI', 'BLE', 'QR']);
      expect(e.tieneVerificacion, isTrue);
    });

    test('es nula cuando no viene y tolera wifiBssids null', () {
      expect(EspacioModel.fromJson(espacioJson()).tieneVerificacion, isFalse);
      final e = EspacioModel.fromJson(
        espacioJson(verificacion: {'wifiBssids': null, 'qrCodigo': 'QR1234'}),
      );
      expect(e.verificacionComplementaria!.wifiBssids, isEmpty);
      expect(e.verificacionComplementaria!.metodos, ['QR']);
    });

    test('toJson produce el cuerpo del PUT y la vacía no está configurada', () {
      const v = VerificacionEspacioModel(wifiBssids: ['aa'], bleUuid: 'b');
      expect(v.toJson(), {
        'wifiBssids': ['aa'],
        'bleUuid': 'b',
        'qrCodigo': '',
      });
      expect(VerificacionEspacioModel.vacia.configurada, isFalse);
    });
  });

  group('generarCodigoQr', () {
    test('usa SIAA-<codigo>-<6 alfanuméricos en mayúscula>', () {
      final qr = generarCodigoQr('aul-101', random: Random(7));
      expect(qr, matches(RegExp(r'^SIAA-AUL-101-[A-Z0-9]{6}$')));
    });

    test('normaliza espacios del código del espacio', () {
      final qr = generarCodigoQr(' Lab 2 ', random: Random(1));
      expect(qr, matches(RegExp(r'^SIAA-LAB-2-[A-Z0-9]{6}$')));
    });

    test('genera códigos distintos', () {
      expect(generarCodigoQr('A'), isNot(generarCodigoQr('A')));
    });
  });

  group('erroresDeCampo', () {
    test('agrupa los detalles de un 422 por campo', () {
      const e = ApiException(
        message: 'Verificación complementaria inválida',
        statusCode: 422,
        details: {
          'codigo': 'VALIDACION',
          'detalles': [
            {'campo': 'wifiBssids', 'error': 'BSSID inválido: x'},
            {'campo': 'wifiBssids', 'error': 'BSSID inválido: y'},
            {'campo': 'qrCodigo', 'error': 'muy corto'},
          ],
        },
      );
      expect(erroresDeCampo(e), {
        'wifiBssids': ['BSSID inválido: x', 'BSSID inválido: y'],
        'qrCodigo': ['muy corto'],
      });
    });

    test('devuelve vacío para errores sin detalles', () {
      expect(erroresDeCampo(Exception('x')), isEmpty);
      expect(erroresDeCampo(const ApiException(message: 'm')), isEmpty);
    });
  });
}
