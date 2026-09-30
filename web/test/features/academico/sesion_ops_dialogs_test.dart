import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/widgets/selector_busqueda.dart';
import 'package:siaa_web/features/academico/data/models/sesion_model.dart';
import 'package:siaa_web/features/academico/presentation/bloc/sesiones_bloc.dart';
import 'package:siaa_web/features/academico/presentation/dialogs/sesion_ops_dialogs.dart';
import 'package:siaa_web/features/geo/data/buscador_espacios.dart';
import 'package:siaa_web/features/usuarios/data/buscador_usuarios.dart';

import 'academico_dialogs_test.dart' show FakeAcademicoRepository;
import 'fake_catalogos.dart';

class _RepoQueCaptura extends FakeAcademicoRepository {
  final aulas = <String>[];
  final suplentes = <String>[];

  @override
  Future<SesionModel> reasignarAulaSesion({
    required String sesionId,
    required String nuevoEspacioId,
    String? motivo,
  }) {
    aulas.add(nuevoEspacioId);
    return super.reasignarAulaSesion(
      sesionId: sesionId,
      nuevoEspacioId: nuevoEspacioId,
    );
  }

  @override
  Future<SesionModel> asignarDocenteReemplazo({
    required String sesionId,
    required String docenteId,
    String? motivo,
  }) {
    suplentes.add(docenteId);
    return super.asignarDocenteReemplazo(
      sesionId: sesionId,
      docenteId: docenteId,
    );
  }
}

final _selector = find.byWidgetPredicate((w) => w is SelectorBusqueda);

void main() {
  late _RepoQueCaptura repo;
  final usuarios = FakeBuscadorUsuarios([docente('doc-5', 'Laura', 'Gómez')]);
  final espacios = FakeBuscadorEspacios([
    aula('esp-1', 'sede-norte', 'A-101', 'Aula 101'),
    aula('esp-2', 'sede-norte', 'A-102', 'Aula 102'),
    aula('esp-9', 'sede-sur', 'S-900', 'Aula Sur'),
  ]);

  setUp(() => repo = _RepoQueCaptura());

  Future<void> abrir(WidgetTester tester, Widget dialogo) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<BuscadorUsuarios>.value(value: usuarios),
          RepositoryProvider<BuscadorEspacios>.value(value: espacios),
        ],
        child: BlocProvider(
          create: (_) => SesionesBloc(repository: repo),
          child: MaterialApp(
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog(
                  context: ctx,
                  builder: (_) => BlocProvider.value(
                    value: ctx.read<SesionesBloc>(),
                    child: dialogo,
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('reasignar aula ofrece aulas de la misma sede, sin la actual', (
    tester,
  ) async {
    await abrir(
      tester,
      const ReasignarAulaDialog(
        sesionId: 'ses-1',
        aulaActual: 'A-101',
        espacioActualId: 'esp-1',
      ),
    );
    await tester.tap(find.text('Reasignar Aula'));
    await tester.pumpAndSettle();
    expect(find.text('Requerido'), findsOneWidget);

    await tester.tap(_selector);
    await tester.pumpAndSettle();
    expect(find.text('A-102 · Aula 102'), findsOneWidget);
    expect(find.text('A-101 · Aula 101'), findsNothing);
    expect(find.text('S-900 · Aula Sur'), findsNothing);

    await tester.tap(find.text('A-102 · Aula 102'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reasignar Aula'));
    await tester.pumpAndSettle();
    expect(repo.aulas, ['esp-2']);
  });

  testWidgets('docente suplente se elige por nombre y envía su id', (
    tester,
  ) async {
    await abrir(
      tester,
      const DocenteReemplazoDialog(sesionId: 'ses-1', docenteActual: 'Ana'),
    );
    await tester.tap(_selector);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'laura');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laura Gómez'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asignar Suplente'));
    await tester.pumpAndSettle();

    expect(usuarios.consultas.last, (texto: 'laura', rol: 'DOCENTE'));
    expect(repo.suplentes, ['doc-5']);
  });
}
