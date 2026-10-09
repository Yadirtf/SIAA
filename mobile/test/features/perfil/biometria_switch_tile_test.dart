// biometria_switch_tile_test.dart — Activar/desactivar biometría desde el perfil (US-AUT-06)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/auth/biometric_auth_service.dart';
import 'package:siaa_mobile/core/auth/preferencia_biometria.dart';
import 'package:siaa_mobile/features/perfil/presentation/widgets/biometria_switch_tile.dart';

void main() {
  late String? guardado;
  late bool verificacionOk;
  late int verificaciones;

  setUp(() {
    guardado = null;
    verificacionOk = true;
    verificaciones = 0;
  });

  Future<void> montar(WidgetTester tester, {bool disponible = true}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BiometriaSwitchTile(
          servicio: BiometricAuthService(
            availabilityChecker: () async => disponible,
            dispositivoSeguroChecker: () async => disponible,
            authInvoker: (_) async {
              verificaciones++;
              return verificacionOk;
            },
            tokenFetcher: () async => 'refresh-1',
          ),
          preferencia: PreferenciaBiometria(
            leer: () async => guardado,
            escribir: (v) async => guardado = v,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  bool valor(WidgetTester tester) =>
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value;

  testWidgets('activa por defecto; desactivar no pide verificación',
      (tester) async {
    await montar(tester);
    expect(valor(tester), isTrue);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(valor(tester), isFalse);
    expect(guardado, 'false');
    expect(verificaciones, 0);
  });

  testWidgets('activar exige verificación local y no se guarda si falla',
      (tester) async {
    guardado = 'false';
    verificacionOk = false;
    await montar(tester);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(verificaciones, 1);
    expect(valor(tester), isFalse);
    expect(guardado, 'false');

    verificacionOk = true;
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(valor(tester), isTrue);
    expect(guardado, 'true');
  });

  testWidgets('se oculta si el dispositivo no tiene biometría ni PIN',
      (tester) async {
    await montar(tester, disponible: false);
    expect(find.byType(SwitchListTile), findsNothing);
  });
}
