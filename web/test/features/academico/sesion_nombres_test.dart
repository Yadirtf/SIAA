import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/academico/data/models/sesion_model.dart';
import 'package:siaa_web/features/academico/presentation/bloc/academico_bloc.dart';
import 'package:siaa_web/features/academico/presentation/bloc/sesiones_bloc.dart';
import 'package:siaa_web/features/academico/presentation/screens/sesiones_screen.dart';

import 'academico_dialogs_test.dart' show FakeAcademicoRepository;

Map<String, dynamic> _json({bool conNombres = true}) => {
  'id': 'ses-1',
  'periodoId': 'per-1',
  'asignacionId': 'asig-1',
  'asignaturaId': 'as-1',
  'grupoId': 'gr-1',
  'docenteIds': ['doc-1', 'doc-2'],
  'espacioId': 'esp-1',
  'fecha': '2026-09-25',
  'horaInicio': '08:00',
  'horaFin': '10:00',
  'estado': 'PROGRAMADA',
  if (conNombres) ...{
    'asignaturaCodigo': 'CAL1',
    'asignaturaNombre': 'Cálculo I',
    'grupoNumero': '01',
    'espacioCodigo': 'A-101',
    'espacioNombre': 'Aula 101',
    'docentesNombres': ['Ana Pérez', ''],
  },
};

class _RepoConNombres extends FakeAcademicoRepository {
  @override
  Future<List<SesionModel>> getSesiones({
    String? periodoId,
    String? docenteId,
    String? espacioId,
    String? fecha,
    String? estado,
    String? desde,
    String? hasta,
  }) async => [SesionModel.fromJson(_json())];
}

void main() {
  test('SesionModel lee los nombres legibles del backend', () {
    final s = SesionModel.fromJson(_json());
    expect(s.aulaTexto, 'A-101 · Aula 101');
    expect(s.grupoTexto, 'Cálculo I · Grupo 01');
    // Sin nombre para el segundo docente: se muestra su id.
    expect(s.docentesTexto, 'Ana Pérez, doc-2');
  });

  test('SesionModel sin nombres cae en los ids (y "Virtual" sin aula)', () {
    final s = SesionModel.fromJson(_json(conNombres: false));
    expect(s.aulaTexto, 'esp-1');
    expect(s.grupoTexto, 'gr-1');
    expect(s.docentesTexto, 'doc-1, doc-2');
    final virtual = SesionModel.fromJson({..._json(), 'espacioId': ''});
    expect(virtual.aulaTexto, 'Virtual');
  });

  testWidgets('las tarjetas y los diálogos de sesión muestran nombres', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AcademicoBloc(repository: _RepoConNombres()),
          ),
          BlocProvider(
            create: (_) => SesionesBloc(repository: _RepoConNombres()),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SesionesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A-101 · Aula 101'), findsOneWidget);
    expect(find.text('Cálculo I'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('Ana Pérez, doc-2'), findsOneWidget);
    expect(find.textContaining('esp-1'), findsNothing);

    await tester.tap(find.byTooltip('Acciones de sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reasignar aula'));
    await tester.pumpAndSettle();
    expect(find.text('Aula actual: A-101 · Aula 101'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Acciones de sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asignar suplente'));
    await tester.pumpAndSettle();
    expect(find.text('Titular actual: Ana Pérez, doc-2'), findsOneWidget);
  });
}
