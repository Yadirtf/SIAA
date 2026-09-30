// espacios_test.dart — Jerarquía Sede → Bloque → Piso → Aula y solapamientos (US-GEO-01/05)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/espacios/data/solapamientos_remote_datasource.dart';
import 'package:siaa_mobile/features/espacios/domain/jerarquia_sede.dart';
import 'package:siaa_mobile/features/espacios/domain/solapamiento_model.dart';
import 'package:siaa_mobile/features/espacios/presentation/screens/espacios_screen.dart';
import 'package:siaa_mobile/features/espacios/presentation/screens/solapamientos_screen.dart';
import 'package:siaa_mobile/features/geo_editor/data/espacio_repository.dart';
import 'package:dio/dio.dart';

EspacioModel _aula(String codigo,
        {String? bloque, int? piso, bool geo = false}) =>
    EspacioModel(
      id: codigo,
      sedeId: 's-1',
      bloqueId: bloque,
      piso: piso,
      codigo: codigo,
      nombre: 'Aula $codigo',
      capacidad: 30,
      tipo: 'AULA',
      estado: 'ACTIVO',
      nivelValidacion: 'AULA',
      bufferMetros: 10,
      areaMetrosCuadrados: geo ? 48 : 0,
      tieneGeometria: geo,
    );

const _bloque = BloqueModel(
    id: 'b-1', sedeId: 's-1', codigo: 'A', nombre: 'Bloque A', pisos: [1, 2]);

class _RepoFake extends EspacioRepository {
  _RepoFake() : super(client: Dio());

  @override
  Future<List<SedeModel>> obtenerSedes() async =>
      const [SedeModel(id: 's-1', codigo: 'CEN', nombre: 'Sede Central')];

  @override
  Future<List<BloqueModel>> obtenerBloques({String? sedeId}) async =>
      const [_bloque];

  @override
  Future<List<EspacioModel>> obtenerEspacios(
          {String? sedeId,
          String? bloqueId,
          String? tipo,
          String? estado}) async =>
      [
        _aula('A-201', bloque: 'b-1', piso: 2),
        _aula('A-101', bloque: 'b-1', piso: 1, geo: true)
      ];
}

class _SolapFake extends SolapamientosRemoteDataSource {
  _SolapFake() : super(dio: Dio());

  @override
  Future<List<SolapamientoModel>> informe({String? sedeId}) async =>
      SolapamientoModel.listaDesde({
        'totalConflictos': 1,
        'conflictos': [
          {
            'sedeId': 's-1',
            'piso': 3,
            'espacio1Id': 'x',
            'espacio1Codigo': 'A-301',
            'espacio1Nombre': 'Aula 301',
            'espacio2Id': 'y',
            'espacio2Codigo': 'A-302',
            'espacio2Nombre': 'Aula 302',
            'areaSolapadaM2': 12.4,
            'porcentajeSolapado': 35.0,
            'esCritico': false
          },
        ],
      });
}

void main() {
  test('JerarquiaSede agrupa por bloque y piso, y aparta aulas sin bloque', () {
    final j = JerarquiaSede(bloques: const [
      _bloque
    ], espacios: [
      _aula('A-201', bloque: 'b-1', piso: 2),
      _aula('A-101', bloque: 'b-1', piso: 1),
      _aula('A-102', bloque: 'b-1', piso: 1),
      _aula('X-1'),
    ]);
    final pisos = j.porPiso('b-1');
    expect(pisos.keys, [1, 2]);
    expect(pisos[1]!.map((e) => e.codigo), ['A-101', 'A-102']);
    expect(j.sinBloque.single.codigo, 'X-1');
    expect(j.totalEn('b-1'), 3);
  });

  test('SolapamientoModel arma etiquetas legibles', () {
    final c = SolapamientoModel.fromJson(const {
      'sedeId': 's',
      'espacio1Codigo': 'A-301',
      'espacio1Nombre': 'Aula 301',
      'espacio2Codigo': 'A-302',
      'espacio2Nombre': '',
      'esCritico': true,
    });
    expect(c.aula1, 'A-301 · Aula 301');
    expect(c.aula2, 'A-302');
    expect(c.esCritico, isTrue);
  });

  testWidgets('Espacios despliega Sede → Bloque → Piso → Aula', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: EspaciosScreen(repository: _RepoFake()))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sede Central'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A — Bloque A'));
    await tester.pumpAndSettle();
    expect(find.text('Piso 1'), findsOneWidget);
    await tester.tap(find.text('Piso 1'));
    await tester.pumpAndSettle();
    expect(find.text('A-101 · Aula A-101'), findsOneWidget);
    expect(find.textContaining('Polígono 48.0 m²'), findsOneWidget);
    // Sin aula:editar-geometria no se ofrece el editor.
    expect(find.byIcon(Icons.edit_location_alt_rounded), findsNothing);
  });

  testWidgets('Solapamientos muestra los pares de aulas y la sede por nombre',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SolapamientosScreen(
                remote: _SolapFake(), espacios: _RepoFake()))));
    await tester.pumpAndSettle();
    expect(find.text('A-301 · Aula 301  ↔  A-302 · Aula 302'), findsOneWidget);
    expect(find.textContaining('Sede Central · Piso 3'), findsOneWidget);
    expect(find.textContaining('35.0 %'), findsOneWidget);
  });
}
