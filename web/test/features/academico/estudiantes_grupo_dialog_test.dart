import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/academico/data/models/estudiante_grupo_model.dart';
import 'package:siaa_web/features/academico/presentation/dialogs/estudiantes_grupo_dialog.dart';

import 'fake_estudiantes_grupo.dart';

Future<void> abrir(WidgetTester tester, EstudiantesGrupoDsFalso ds) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => EstudiantesGrupoDialog.mostrar(
              context,
              grupoId: 'g1',
              titulo: 'Cálculo – Grupo 1',
              cupo: 30,
              dataSource: ds,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista, filtra, quita, agrega y guarda mostrando el resultado', (
    tester,
  ) async {
    final ds = EstudiantesGrupoDsFalso()
      ..respuesta = const ResultadoEstudiantesGrupo(
        estudiantes: [anaGrupo],
        noEncontrados: ['nadie@uni.edu.co'],
      );
    await abrir(tester, ds);

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Luis Gómez'), findsOneWidget);
    expect(find.textContaining('Doc. 1001'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('buscar-estudiantes')), 'luis');
    await tester.pump();
    expect(find.text('Ana Pérez'), findsNothing);
    await tester.enterText(find.byKey(const Key('buscar-estudiantes')), '');
    await tester.pump();

    await tester.tap(find.byTooltip('Quitar Luis Gómez'));
    await tester.pump();
    expect(find.text('Luis Gómez'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('agregar-estudiantes')),
      'nadie@uni.edu.co',
    );
    await tester.tap(find.text('Agregar'));
    await tester.pump();
    expect(find.text('Pendiente por guardar'), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(ds.enviados, ['u1', 'nadie@uni.edu.co']);
    expect(find.textContaining('queda con 1 estudiante'), findsOneWidget);
    expect(find.textContaining('No encontrados (1)'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
  });

  testWidgets('muestra el mensaje de error del servidor', (tester) async {
    final ds = EstudiantesGrupoDsFalso()
      ..errorAlGuardar = 'La lista supera el cupo del grupo';
    await abrir(tester, ds);
    await tester.tap(find.byTooltip('Quitar Ana Pérez'));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(ds.enviados, ['u2']);
    expect(find.text('La lista supera el cupo del grupo'), findsOneWidget);
  });
}
