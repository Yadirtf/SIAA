import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/core/network/confirmacion_requerida.dart';
import 'package:siaa_web/core/widgets/confirmar_operacion.dart';

const _pideConfirmar = ApiException(
  statusCode: 409,
  message: 'Ya hay un periodo activo (2026-1) con fechas que se cruzan.',
  details: {'codigo': 'CONFIRMACION_REQUERIDA'},
);

void main() {
  test('solo reconoce el 409 CONFIRMACION_REQUERIDA', () {
    expect(requiereConfirmacion(_pideConfirmar), isTrue);
    expect(
      requiereConfirmacion(
        const ApiException(
          statusCode: 409,
          message: 'cruce',
          details: {'codigo': 'CONFLICTO_HORARIO'},
        ),
      ),
      isFalse,
    );
    expect(requiereConfirmacion(Exception('x')), isFalse);
  });

  Future<List<bool>> ejecutar(
    WidgetTester tester, {
    required String respuesta,
    void Function(bool?)? alTerminar,
  }) async {
    final llamadas = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              final ok = await ejecutarConConfirmacion(ctx, (confirmar) async {
                llamadas.add(confirmar);
                if (!confirmar) throw _pideConfirmar;
              });
              alTerminar?.call(ok);
            },
            child: const Text('Guardar'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('se cruzan'), findsOneWidget);
    await tester.tap(find.text(respuesta));
    await tester.pumpAndSettle();
    return llamadas;
  }

  testWidgets('al confirmar repite la operación con confirmar = true', (
    tester,
  ) async {
    bool? resultado;
    final llamadas = await ejecutar(
      tester,
      respuesta: 'Sí, continuar',
      alTerminar: (ok) => resultado = ok,
    );
    expect(llamadas, [false, true]);
    expect(resultado, isTrue);
  });

  testWidgets('si no confirma no la repite y devuelve false', (tester) async {
    bool? resultado;
    final llamadas = await ejecutar(
      tester,
      respuesta: 'No, volver',
      alTerminar: (ok) => resultado = ok,
    );
    expect(llamadas, [false]);
    expect(resultado, isFalse);
  });
}
