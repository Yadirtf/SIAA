// aviso_privacidad_widget_test.dart — Botones explícitos del aviso (US-LEG-01 AC-01)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/privacidad/data/consentimiento_gate.dart';
import 'package:siaa_mobile/features/privacidad/data/privacidad_remote_datasource.dart';
import 'package:siaa_mobile/features/privacidad/domain/models/estado_consentimiento.dart';
import 'package:siaa_mobile/features/privacidad/domain/models/politica_privacidad.dart';
import 'package:siaa_mobile/features/privacidad/presentation/cubit/consentimiento_cubit.dart';
import 'package:siaa_mobile/features/privacidad/presentation/widgets/privacidad_view.dart';

class MockRemote extends Mock implements PrivacidadRemoteDataSource {}

void main() {
  testWidgets(
      'muestra el aviso y registra "No acepto" con el canal de contacto',
      (tester) async {
    final remote = MockRemote();
    when(() => remote.obtenerPolitica())
        .thenAnswer((_) async => const PoliticaPrivacidad(
              version: '1.0',
              contenido:
                  '# Tratamiento de datos\n- Ubicación puntual al marcar',
              contacto: 'privacidad@uni.edu.co',
            ));
    when(() => remote.obtenerConsentimiento()).thenAnswer((_) async =>
        const EstadoConsentimiento(
            versionVigente: '1.0', requiereAceptacion: true));
    when(() => remote.registrarDecision(
          version: '1.0',
          acepta: false,
          dispositivoId: 'inst-1',
        )).thenAnswer((_) async => const EstadoConsentimiento(
          versionVigente: '1.0',
          requiereAceptacion: true,
          decision: 'RECHAZADO',
          versionDecidida: '1.0',
        ));
    final cubit = ConsentimientoCubit(
      remote: remote,
      gate: ConsentimientoGate(
          leerVersion: () async => null, guardarVersion: (_) async {}),
      instalacionId: () async => 'inst-1',
    );
    bool? decidido;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: PrivacidadView(onDecidido: (a) => decidido = a),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tratamiento de datos'), findsOneWidget);
    expect(find.text('Acepto'), findsOneWidget);
    expect(find.text('No acepto'), findsOneWidget);

    await tester.tap(find.text('No acepto'));
    await tester.pumpAndSettle();

    expect(decidido, isFalse);
    expect(find.textContaining('privacidad@uni.edu.co'), findsWidgets);
    // Tras rechazar se ofrece aceptar más tarde.
    expect(find.text('Acepto'), findsOneWidget);
    expect(find.text('No acepto'), findsNothing);
    await cubit.close();
  });
}
