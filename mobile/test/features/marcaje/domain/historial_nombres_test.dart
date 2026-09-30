// historial_nombres_test.dart — Historial y listado de marcajes con nombres (US-MAR-08/09)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_historial_model.dart';
import 'package:siaa_mobile/features/marcaje/presentation/widgets/historial_item_card.dart';

const itemBackend = {
  'id': 'm-1',
  'sesionId': 'ses-1',
  'usuarioId': '65f0aa11bb22cc33dd44ee55',
  'espacioId': '65f0aa11bb22cc33dd44ee77',
  'tipo': 'ENTRADA',
  'resultado': 'TARDANZA',
  'origen': 'APP_MOVIL',
  'geolocalizacion': {
    'coordenadas': [-74.06, 4.60],
    'precisionMetros': 7.5
  },
  'distanciaMetros': 3.2,
  'timestampServidor': '2026-09-28T13:05:00Z',
  'timestampDispositivo': '2026-09-28T13:04:58Z',
  'anulado': false,
  'usuarioNombre': 'Ana Gómez',
  'asignaturaNombre': 'Cálculo I',
  'grupoNumero': '01',
  'espacioCodigo': 'A-301',
};

void main() {
  test('parsea {items,...} del backend con nombres legibles', () {
    final p = HistorialPaginadoModel.fromJson({
      'items': [itemBackend],
      'total': 45,
      'pagina': 1,
      'limite': 20,
      'totalPaginas': 3,
    });
    final m = p.items.single;
    expect(m.usuarioNombre, 'Ana Gómez');
    expect(m.tituloSesion, 'Cálculo I · Grupo 01');
    expect(m.espacioCodigo, 'A-301');
    expect(m.categoria, CategoriaResultado.tardanza);
    expect(m.esAceptado, isTrue);
    expect(m.precisionMetros, 7.5);
    expect(m.latitud, 4.60);
    expect(p.hayMas, isTrue);
  });

  test('sin nombres del backend no muestra identificadores', () {
    final m = MarcajeHistorialItem.fromJson(const {
      'id': 'm-2',
      'sesionId': 's',
      'resultado': 'RECHAZADO_FUERA_DE_AREA',
      'timestampServidor': '2026-09-28T13:05:00Z',
    });
    expect(m.tituloSesion, 'Sesión sin asignatura');
    expect(m.esRechazado, isTrue);
    expect(etiquetaResultado(m.resultado), 'Fuera del aula');
  });

  testWidgets('HistorialItemCard muestra asignatura, grupo y estado por color',
      (tester) async {
    final m = MarcajeHistorialItem.fromJson(itemBackend);
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HistorialItemCard(item: m))));
    expect(find.text('Cálculo I · Grupo 01'), findsOneWidget);
    expect(find.text('TARDANZA'), findsOneWidget);
    expect(find.textContaining('65f0'), findsNothing);
  });
}
