import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/parametros/domain/models/parametro_model.dart';
import 'package:siaa_web/features/parametros/domain/parametros_repository.dart';
import 'package:siaa_web/features/parametros/presentation/bloc/parametros_bloc.dart';
import 'package:siaa_web/features/parametros/presentation/widgets/parametro_card.dart';

class _FakeParametrosRepository implements ParametrosRepository {
  final guardados = <GuardarParametroRequest>[];

  @override
  Future<ParametrosSnapshot> obtenerEfectivos({
    String? sedeId,
    String? facultadId,
    String? bloqueId,
    String? espacioId,
    String? asignacionId,
  }) async => const ParametrosSnapshot(parametros: []);

  @override
  Future<void> guardarParametro(GuardarParametroRequest request) async {
    guardados.add(request);
  }
}

void main() {
  testWidgets('un booleano se edita con Sí/No y se guarda como bool', (
    tester,
  ) async {
    final repo = _FakeParametrosRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider(
            create: (_) => ParametrosBloc(repository: repo),
            child: const ParametroCard(
              parametro: ParametroEfectivoModel(
                clave: 'exigir_attestation',
                valor: false,
                nivel: 'GLOBAL',
                nivelId: '',
              ),
              ambitoDestino: 'GLOBAL',
              ambitoDestinoId: '',
              isSaving: false,
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('Verificar la app con Google (Play Integrity)'),
      findsOneWidget,
    );
    expect(find.text('Valor global'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí').last);
    await tester.pumpAndSettle();
    expect(find.text('Sí'), findsOneWidget);

    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.guardados.single.clave, 'exigir_attestation');
    expect(repo.guardados.single.valor, isTrue);
  });
}
