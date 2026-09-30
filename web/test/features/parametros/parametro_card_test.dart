import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/parametros/domain/models/parametro_model.dart';
import 'package:siaa_web/features/parametros/domain/parametros_repository.dart';
import 'package:siaa_web/features/parametros/presentation/bloc/parametros_bloc.dart';
import 'package:siaa_web/features/parametros/presentation/widgets/parametro_card.dart';
import 'package:siaa_web/features/parametros/presentation/widgets/parametro_labels.dart';

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
  test(
    'exigir_attestation y verificacion_complementaria tienen etiqueta y ayuda',
    () {
      expect(
        etiquetaParametro('exigir_attestation'),
        'Exigir attestation de Play Integrity',
      );
      expect(
        ayudaParametro('exigir_attestation'),
        contains('PLAY_INTEGRITY_PACKAGE'),
      );
      expect(
        ayudaParametro('exigir_attestation'),
        contains('PLAY_INTEGRITY_CREDENTIALS'),
      );
      expect(
        ayudaParametro('verificacion_complementaria'),
        'Exigir verificación complementaria (WiFi/BLE/QR) en aulas que la tengan configurada',
      );
      expect(etiquetaParametro('clave_nueva'), 'clave_nueva');
      expect(ayudaParametro('umbral_tardanza_min'), isNull);
    },
  );

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

    expect(find.text('Exigir attestation de Play Integrity'), findsOneWidget);
    expect(find.textContaining('PLAY_INTEGRITY_PACKAGE'), findsOneWidget);
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
