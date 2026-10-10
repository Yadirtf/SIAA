// codigo_qr_dialog_test.dart — Lector QR por cámara con respaldo manual (US-GEO-13 AC-05)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/lectura_baliza.dart';
import 'package:siaa_mobile/features/marcaje/presentation/widgets/busqueda_baliza_dialog.dart';
import 'package:siaa_mobile/features/marcaje/presentation/widgets/codigo_qr_dialog.dart';

/// Doble de la cámara: expone los callbacks para simular lectura o error.
class _CamaraFalsa {
  void Function(String)? onCodigo;
  void Function(String)? onError;

  Widget construir(void Function(String) c, void Function(String) e) {
    onCodigo = c;
    onError = e;
    return const ColoredBox(key: Key('camara-falsa'), color: Color(0xFF000000));
  }
}

void main() {
  late _CamaraFalsa camara;
  late Future<String?> resultado;

  Future<void> abrir(WidgetTester tester, {bool otro = false}) async {
    camara = _CamaraFalsa();
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => resultado = CodigoQrDialog.show(context,
              otroMetodoIntentado: otro, constructorCamara: camara.construir),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('al leer el QR se adjunta sin pasos adicionales', (tester) async {
    await abrir(tester);
    expect(find.byKey(const Key('camara-falsa')), findsOneWidget);
    expect(find.text('Continuar'), findsNothing);

    camara.onCodigo!('  AULA-301-QR ');
    await tester.pumpAndSettle();

    expect(await resultado, 'AULA-301-QR');
    expect(find.byType(CodigoQrDialog), findsNothing);
  });

  testWidgets('cámara denegada pasa a escribir el código', (tester) async {
    await abrir(tester, otro: true);
    camara.onError!('No se concedió el permiso de cámara.');
    await tester.pumpAndSettle();

    expect(find.textContaining('No se concedió el permiso de cámara.'),
        findsOneWidget);
    expect(find.text('Escanear con la cámara'), findsNothing);
    await tester.enterText(find.byType(TextField), 'B4-201-XQ');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(await resultado, 'B4-201-XQ');
  });

  testWidgets('el docente puede elegir escribir el código y cancelar',
      (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Escribir el código'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Escanear con la cámara'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await resultado, isNull);
  });

  testWidgets('BusquedaBalizaDialog devuelve la lectura y se puede omitir',
      (tester) async {
    late Future<LecturaBaliza> lectura;
    final pendiente = <Future<LecturaBaliza> Function()>[
      () async => const LecturaBaliza.encontrada('abc'),
      () => Future<LecturaBaliza>.delayed(const Duration(seconds: 30),
          () => const LecturaBaliza.encontrada('tarde')),
    ];
    var i = 0;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => lectura =
              BusquedaBalizaDialog.show(context, buscar: pendiente[i++]),
          child: const Text('buscar'),
        ),
      ),
    ));
    await tester.tap(find.text('buscar'));
    await tester.pumpAndSettle();
    expect((await lectura).uuid, 'abc');

    await tester.tap(find.text('buscar'));
    await tester.pump();
    expect(find.textContaining('Buscando la baliza'), findsOneWidget);
    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();
    expect((await lectura).motivo, MotivoSinBaliza.noEncontrada);
    await tester.pump(const Duration(seconds: 31));
  });
}
