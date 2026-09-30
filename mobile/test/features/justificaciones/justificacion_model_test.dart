import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/catalogo_justificacion.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/justificacion_model.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/soporte_adjunto.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_historial_model.dart';

void main() {
  group('Justificacion.fromJson', () {
    test('parsea adjuntos, historial y observaciones del revisor', () {
      final j = Justificacion.fromJson(const {
        'id': 'j1',
        'sesionId': 's1',
        'docenteId': 'd1',
        'tipo': 'INCAPACIDAD',
        'descripcion': 'Incapacidad médica de dos días',
        'estado': 'RECHAZADA',
        'adjuntos': [
          {
            'id': 'a1',
            'nombre': 'incapacidad.pdf',
            'mime': 'application/pdf',
            'tamano': 2048,
            'sha256': 'abc',
          }
        ],
        'revisorId': 'r1',
        'observaciones': 'El soporte no es legible',
        'historial': [
          {'estado': 'RADICADA', 'actorId': 'd1', 'en': '2026-09-01T13:00:00Z'},
          {
            'estado': 'RECHAZADA',
            'actorId': 'r1',
            'observaciones': 'El soporte no es legible',
            'en': '2026-09-02T15:30:00Z',
          },
        ],
        'fechaSesion': '2026-08-31',
        'nombreSesion': 'Cálculo I - G1',
        'creadoEn': '2026-09-01T13:00:00Z',
        'actualizadoEn': '2026-09-02T15:30:00Z',
      });

      expect(j.id, 'j1');
      expect(j.tipoEtiqueta, 'Incapacidad médica');
      expect(j.estadoConocido, EstadoJustificacion.rechazada);
      expect(j.estaCerrada, isTrue);
      expect(j.adjuntos.single.esPdf, isTrue);
      expect(j.adjuntos.single.tamano, 2048);
      expect(j.historial, hasLength(2));
      expect(j.historial.first.observaciones, isNull);
      expect(j.historial.last.en, DateTime.utc(2026, 9, 2, 15, 30));
      expect(j.observaciones, 'El soporte no es legible');
      expect(j.fechaSesion, '2026-08-31');
      expect(j.nombreSesion, 'Cálculo I - G1');
    });

    test('tolera campos nulos o ausentes', () {
      final j = Justificacion.fromJson(const {
        'id': 'j2',
        'estado': 'RADICADA',
        'adjuntos': null,
        'historial': null,
        'revisorId': '',
        'observaciones': '',
      });
      expect(j.adjuntos, isEmpty);
      expect(j.historial, isEmpty);
      expect(j.revisorId, isNull);
      expect(j.observaciones, isNull);
      expect(j.creadoEn, isNull);
      expect(j.estaCerrada, isFalse);
    });

    test('estado desconocido conserva el código como etiqueta', () {
      expect(EstadoJustificacion.desdeCodigo('OTRO'), isNull);
      expect(EstadoJustificacion.etiquetaDe('OTRO'), 'OTRO');
    });
  });

  group('SoporteAdjunto.validar', () {
    SoporteAdjunto archivo(String nombre, int bytes) =>
        SoporteAdjunto(nombre: nombre, bytes: Uint8List(bytes));

    test('acepta JPG, PNG y PDF dentro del límite', () {
      expect(archivo('foto.JPG', 10).validar(), isNull);
      expect(archivo('captura.png', 10).mime, 'image/png');
      expect(archivo('soporte.pdf', ReglasSoporte.maxBytes).validar(), isNull);
    });

    test('rechaza formatos no permitidos, vacíos y mayores a 10 MB', () {
      expect(archivo('doc.docx', 10).validar(), contains('no es JPG'));
      expect(archivo('vacio.pdf', 0).validar(), contains('vacío'));
      expect(archivo('grande.pdf', ReglasSoporte.maxBytes + 1).validar(),
          contains('10 MB'));
    });
  });

  group('MarcajeHistorialItem.puedeJustificarse', () {
    MarcajeHistorialItem item(String resultado, {bool anulado = false}) =>
        MarcajeHistorialItem(
          id: 'm1',
          sesionId: 's1',
          tipo: 'ENTRADA',
          resultado: resultado,
          origen: 'MOVIL_ONLINE',
          asignatura: 'Cálculo',
          grupo: 'G1',
          espacioCodigo: 'A-101',
          timestampServidor: DateTime(2026, 9, 1),
          timestampDispositivo: DateTime(2026, 9, 1),
          anulado: anulado,
        );

    test('habilita ausencias y rechazos', () {
      for (final r in [
        'AUSENTE',
        'RECHAZADO_FUERA_DE_AREA',
        'RECHAZADO_FUERA_DE_HORARIO',
        'RECHAZADO_INTEGRIDAD',
        'FUERA_DE_AREA',
        'FUERA_DE_TIEMPO',
      ]) {
        expect(item(r).puedeJustificarse, isTrue, reason: r);
      }
    });

    test('no habilita aceptados ni anulados', () {
      expect(item('ACEPTADO').puedeJustificarse, isFalse);
      expect(item('AUSENTE', anulado: true).puedeJustificarse, isFalse);
    });
  });
}
