import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/justificaciones/data/models/justificacion_catalogos.dart';
import 'package:siaa_web/features/justificaciones/data/models/justificacion_model.dart';
import 'package:siaa_web/features/justificaciones/data/models/justificaciones_filtro.dart';

void main() {
  test('fromJson lee adjuntos, historial y datos de la sesión', () {
    final j = JustificacionModel.fromJson({
      'id': 'j1',
      'sesionId': 's1',
      'docenteId': 'd1',
      'tipo': 'INCAPACIDAD',
      'descripcion': 'Incapacidad médica por tres días',
      'estado': 'EN_REVISION',
      'adjuntos': [
        {
          'id': 'a1',
          'nombre': 'incapacidad.pdf',
          'mime': 'application/pdf',
          'tamano': 2048,
          'sha256': 'abc',
        },
      ],
      'revisorId': 'r1',
      'historial': [
        {'estado': 'RADICADA', 'actorId': 'd1', 'en': '2026-09-01T13:00:00Z'},
        {
          'estado': 'EN_REVISION',
          'actorId': 'r1',
          'observaciones': 'Validando soporte',
          'en': '2026-09-02T13:00:00Z',
        },
      ],
      'fechaSesion': '2026-08-30',
      'nombreSesion': 'Cálculo I - G1',
      'creadoEn': '2026-09-01T13:00:00Z',
    });

    expect(j.id, 'j1');
    expect(j.tipo, 'INCAPACIDAD');
    expect(j.adjuntos.single.esPdf, isTrue);
    expect(j.adjuntos.single.tamanoTexto, '2.0 KB');
    expect(j.historial, hasLength(2));
    expect(j.historial.last.observaciones, 'Validando soporte');
    expect(j.historial.first.observaciones, isNull);
    expect(j.revisorId, 'r1');
    expect(j.observaciones, isNull);
    expect(j.fechaSesion, '2026-08-30');
    expect(j.nombreSesion, 'Cálculo I - G1');
    expect(j.creadoEn, isNotNull);
  });

  test('fromJson tolera campos ausentes', () {
    final j = JustificacionModel.fromJson({'id': 'j2'});
    expect(j.adjuntos, isEmpty);
    expect(j.historial, isEmpty);
    expect(j.revisorId, isNull);
  });

  test('el filtro por defecto pide las radicadas y omite vacíos', () {
    const f = JustificacionesFiltro();
    expect(f.toQuery(), {'estado': 'RADICADA', 'pagina': '1', 'limite': '25'});
    final g = f.copyWith(
      estado: () => null,
      tipo: () => 'PERMISO',
      desde: () => '2026-09-01',
      pagina: 3,
    );
    expect(g.toQuery(), {
      'tipo': 'PERMISO',
      'desde': '2026-09-01',
      'pagina': '3',
      'limite': '25',
    });
  });

  test('catálogos: etiquetas y estados pendientes', () {
    expect(
      JustificacionCatalogos.etiquetaTipo('FALLA_TECNICA'),
      'Falla técnica',
    );
    expect(JustificacionCatalogos.esPendiente('EN_REVISION'), isTrue);
    expect(JustificacionCatalogos.esPendiente('APROBADA'), isFalse);
  });
}
