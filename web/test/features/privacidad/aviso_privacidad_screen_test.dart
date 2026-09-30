import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/features/privacidad/data/privacidad_remote_datasource.dart';
import 'package:siaa_web/features/privacidad/presentation/screens/aviso_privacidad_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  PrivacidadRemoteDataSource ds(Future<http.Response> Function() r) =>
      PrivacidadRemoteDataSource(
        client: ApiClient(client: MockClient((_) => r())),
      );

  Future<void> montar(WidgetTester t, PrivacidadRemoteDataSource d) =>
      t.pumpWidget(MaterialApp(home: AvisoPrivacidadScreen(dataSource: d)));

  testWidgets('muestra carga mientras llega la política', (tester) async {
    final pendiente = Completer<http.Response>();
    await montar(tester, ds(() => pendiente.future));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pendiente.complete(http.Response('{"version":"1.0"}', 200));
    await tester.pumpAndSettle();
  });

  testWidgets('renderiza cabecera y contenido markdown', (tester) async {
    await montar(
      tester,
      ds(
        () async => http.Response(
          jsonEncode({
            'version': '1.0',
            'contenido':
                '# Tratamiento de datos\n\nRecolectamos **ubicación**.\n\n'
                '- Finalidad uno\n- Finalidad dos',
            'actualizadaEn': '2026-09-30',
            'institucion': 'Universidad Ejemplo',
            'contacto': 'privacidad@ejemplo.edu.co',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aviso de privacidad'), findsOneWidget);
    expect(find.text('Universidad Ejemplo'), findsOneWidget);
    expect(find.textContaining('1.0', findRichText: true), findsWidgets);
    expect(
      find.textContaining('privacidad@ejemplo.edu.co', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('Tratamiento de datos', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('Recolectamos ubicación.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Finalidad dos', findRichText: true), findsOneWidget);
    expect(find.text('•'), findsNWidgets(2));
  });

  testWidgets('error con reintento', (tester) async {
    var llamadas = 0;
    await montar(
      tester,
      ds(() async {
        llamadas++;
        return http.Response(jsonEncode({'mensaje': 'Servicio caído'}), 503);
      }),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudo cargar el aviso de privacidad'),
      findsOneWidget,
    );
    expect(find.text('Servicio caído'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(llamadas, 2);
  });

  test('solicitadaEn detecta ?vista=privacidad', () {
    expect(
      AvisoPrivacidadScreen.solicitadaEn(
        Uri.parse('http://x/?vista=privacidad'),
      ),
      isTrue,
    );
    expect(AvisoPrivacidadScreen.solicitadaEn(Uri.parse('http://x/')), isFalse);
  });
}
