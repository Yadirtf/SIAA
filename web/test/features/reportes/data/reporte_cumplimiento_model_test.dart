import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/reportes/data/models/filtro_reporte_model.dart';
import 'package:siaa_web/features/reportes/data/models/reporte_cumplimiento_model.dart';

void main() {
  test('fromJson lee filas, totales y falsos rechazos', () {
    final r = ReporteCumplimientoModel.fromJson({
      'filtro': {'periodoId': 'p1', 'facultadId': ''},
      'generadoEn': '2026-09-29T15:00:00Z',
      'docentes': [
        {
          'docenteId': 'd1',
          'nombre': 'Ana Pérez',
          'documento': '1020',
          'sesiones': 10,
          'horasProgramadas': 20,
          'horasDictadas': 17.5,
          'horasJustificadas': 2,
          'presentes': 8,
          'tardanzas': 1,
          'ausenciasJustificadas': 1,
          'ausenciasInjustificadas': 0,
          'ajustadas': 1,
          'porcentajeCumplimiento': 97.2,
        },
      ],
      'totales': {
        'sesiones': 10,
        'tardanzas': 1,
        'porcentajeCumplimiento': 97.2,
      },
      'falsosRechazos': 3,
    });

    expect(r.filtro.periodoId, 'p1');
    expect(r.filtro.facultadId, isNull);
    expect(r.generadoEn, isNotNull);
    final d = r.docentes.single;
    expect(d.nombre, 'Ana Pérez');
    expect(d.horasDictadas, 17.5);
    expect(d.horasProgramadas, 20.0);
    expect(d.ajustadas, 1);
    expect(r.totales.sesiones, 10);
    expect(r.totales.nombre, isEmpty);
    expect(r.falsosRechazos, 3);
  });

  test('el filtro exige periodo o rango completo', () {
    const vacio = FiltroReporteModel();
    expect(vacio.esValido, isFalse);
    expect(vacio.copyWith(desde: () => '2026-09-01').esValido, isFalse);
    final rango = vacio.copyWith(
      desde: () => '2026-09-01',
      hasta: () => '2026-09-30',
    );
    expect(rango.esValido, isTrue);
    expect(rango.toQuery(), {'desde': '2026-09-01', 'hasta': '2026-09-30'});
    expect(vacio.copyWith(periodoId: () => 'p1').esValido, isTrue);
  });
}
