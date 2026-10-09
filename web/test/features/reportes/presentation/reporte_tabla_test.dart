import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/theme/app_colors.dart';
import 'package:siaa_web/features/reportes/data/models/reporte_cumplimiento_model.dart';
import 'package:siaa_web/features/reportes/presentation/widgets/reporte_tabla.dart';

void main() {
  final reporte = ReporteCumplimientoModel.fromJson({
    'docentes': [
      {
        'docenteId': 'd1',
        'nombre': 'Ana Pérez',
        'porcentajeCumplimiento': 95.0,
        'salidasFaltantes': 0,
        'bajoUmbral': false,
      },
      {
        'docenteId': 'd2',
        'nombre': 'Bruno Díaz',
        'porcentajeCumplimiento': 62.5,
        'salidasFaltantes': 4,
        'bajoUmbral': true,
      },
    ],
    'totales': {'porcentajeCumplimiento': 78.7, 'salidasFaltantes': 4},
    'umbralAlerta': 80,
  });

  test('fromJson lee salidas faltantes, bajo umbral y el umbral', () {
    expect(reporte.umbralAlerta, 80);
    expect(reporte.docentes[1].salidasFaltantes, 4);
    expect(reporte.docentes[1].bajoUmbral, isTrue);
    expect(reporte.docentes[0].bajoUmbral, isFalse);
    expect(reporte.totales.salidasFaltantes, 4);
  });

  testWidgets('muestra salidas faltantes y resalta filas bajo el umbral', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReporteTabla(
              docentes: reporte.docentes,
              totales: reporte.totales,
              umbralAlerta: reporte.umbralAlerta,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Salidas faltantes'), findsOneWidget);
    expect(find.text('4'), findsNWidgets(2)); // fila y totales

    final tabla = tester.widget<DataTable>(find.byType(DataTable));
    Color? fondo(int i) => tabla.rows[i].color?.resolve({});
    expect(fondo(0), isNull);
    expect(fondo(1), AppColors.statusDangerBg);
    expect(find.byTooltip('Por debajo del umbral de alerta'), findsOneWidget);
  });
}
