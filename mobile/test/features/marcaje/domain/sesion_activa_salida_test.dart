// sesion_activa_salida_test.dart — Ventana de salida, modo y permanencia en la sesión activa (US-MAR-15)
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_result_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/sesion_activa_model.dart';

Map<String, dynamic> _detalle({
  String? tipoVentana,
  String? modo,
  Map<String, dynamic>? salida,
}) =>
    {
      'sesion': {'id': 'ses-1', 'asignatura': 'Redes', 'grupo': 'G1'},
      'ventana': {
        'abreEn': '2026-09-25T08:45:00Z',
        'cierraEn': '2026-09-25T09:15:00Z',
        'estado': 'ABIERTA',
        if (tipoVentana != null) 'tipo': tipoVentana,
      },
      'parametros': {if (modo != null) 'marcajeSalida': modo},
      'marcajeExistente': {'tipo': 'ENTRADA', 'resultado': 'PRESENTE'},
      if (salida != null) 'marcajeSalida': salida,
    };

void main() {
  group('SesionActivaModel — marcaje de salida (US-MAR-15)', () {
    test('sin tipo de ventana se asume ENTRADA y no admite repetir entrada',
        () {
      final m = SesionActivaModel.fromDetalleJson(_detalle(modo: 'OPCIONAL'));
      expect(m.ventana.tipo, 'ENTRADA');
      expect(m.tipoMarcaje, 'ENTRADA');
      expect(m.tieneMarcajeEntrada, isTrue);
      expect(m.marcajeVentanaRegistrado, isTrue);
      expect(m.admiteMarcaje, isFalse);
    });

    test('ventana SALIDA con modo OBLIGATORIO admite marcar salida', () {
      final m = SesionActivaModel.fromDetalleJson(
          _detalle(tipoVentana: 'SALIDA', modo: 'OBLIGATORIO'));
      expect(m.ventana.esSalida, isTrue);
      expect(m.tipoMarcaje, 'SALIDA');
      expect(m.modoMarcajeSalida, 'OBLIGATORIO');
      expect(m.tieneMarcajeSalida, isFalse);
      expect(m.admiteMarcaje, isTrue);
      expect(m.permanenciaSalidaMin, isNull);
    });

    test('salida aceptada ya registrada trae permanencia y bloquea el marcaje',
        () {
      final m = SesionActivaModel.fromDetalleJson(_detalle(
        tipoVentana: 'SALIDA',
        modo: 'OPCIONAL',
        salida: {'tipo': 'SALIDA', 'resultado': 'VALIDO', 'permanenciaMin': 95},
      ));
      expect(m.tieneMarcajeSalida, isTrue);
      expect(m.permanenciaSalidaMin, 95);
      expect(m.admiteMarcaje, isFalse);
    });

    test('salida rechazada no cuenta como registrada', () {
      final m = SesionActivaModel.fromDetalleJson(_detalle(
        tipoVentana: 'SALIDA',
        modo: 'OPCIONAL',
        salida: {'tipo': 'SALIDA', 'resultado': 'RECHAZADO_FUERA_DE_AREA'},
      ));
      expect(m.tieneMarcajeSalida, isFalse);
      expect(m.admiteMarcaje, isTrue);
    });

    test('modo DESACTIVADO nunca admite salida (AC-03)', () {
      final m = SesionActivaModel.fromDetalleJson(
          _detalle(tipoVentana: 'SALIDA', modo: 'DESACTIVADO'));
      expect(m.salidaDesactivada, isTrue);
      expect(m.admiteMarcaje, isFalse);
    });
  });

  test('MarcajeResultModel deserializa permanenciaMin de una salida', () {
    final r = MarcajeResultModel.fromJson(
        {'resultado': 'VALIDO', 'mensaje': 'ok', 'permanenciaMin': 40});
    expect(r.permanenciaMin, 40);
    expect(r.toJson()['permanenciaMin'], 40);
    expect(MarcajeResultModel.fromJson({'resultado': 'VALIDO'}).permanenciaMin,
        isNull);
  });
}
