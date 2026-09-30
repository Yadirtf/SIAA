// editor_gps_screen_test.dart — "Editor GPS": seleccionar Sede → Bloque → Aula y trazar
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/geo_editor/data/espacio_repository.dart';
import 'package:siaa_mobile/features/home/presentation/bloc/home_bloc.dart';
import 'package:siaa_mobile/features/home/presentation/screens/editor_gps_screen.dart';

import 'home_bloc_test.dart' show MockEspacioRepository;

void main() {
  testWidgets('carga sedes reales del repositorio y lista las aulas del bloque',
      (tester) async {
    final repo = MockEspacioRepository(
      sedesMock: const [
        SedeModel(id: 's-1', codigo: 'CEN', nombre: 'Sede Central')
      ],
      bloquesMock: const [
        BloqueModel(
            id: 'b-1',
            sedeId: 's-1',
            codigo: 'A',
            nombre: 'Bloque A',
            pisos: [1]),
      ],
      espaciosMock: const [
        EspacioModel(
          id: 'e-1',
          sedeId: 's-1',
          bloqueId: 'b-1',
          piso: 1,
          codigo: 'A-101',
          nombre: 'Aula 101',
          capacidad: 30,
          tipo: 'AULA',
          estado: 'ACTIVO',
          nivelValidacion: 'AULA',
          bufferMetros: 10,
          areaMetrosCuadrados: 0,
          tieneGeometria: false,
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp(
        home:
            Scaffold(body: EditorGpsScreen(bloc: HomeBloc(repository: repo)))));
    await tester.pumpAndSettle();
    expect(find.text('CEN — Sede Central'), findsOneWidget);
    expect(find.text('A-101'), findsOneWidget);
    // Sin AppBar propia: se aloja en el shell.
    expect(find.byType(AppBar), findsNothing);
  });
}
