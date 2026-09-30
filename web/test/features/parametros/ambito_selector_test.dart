import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/models/opcion_catalogo.dart';
import 'package:siaa_web/core/widgets/selector_busqueda.dart';
import 'package:siaa_web/features/parametros/data/opciones_ambito_datasource.dart';
import 'package:siaa_web/features/parametros/presentation/widgets/ambito_selector.dart';

class _FuenteFalsa implements FuenteOpcionesAmbito {
  final niveles = <String>[];

  @override
  Future<List<OpcionCatalogo>> opciones(String nivel) async {
    niveles.add(nivel);
    return switch (nivel) {
      'SEDE' => const [
        OpcionCatalogo(id: 's-1', etiqueta: 'CEN · Sede Centro'),
        OpcionCatalogo(id: 's-2', etiqueta: 'NOR · Sede Norte'),
      ],
      _ => const [],
    };
  }
}

void main() {
  testWidgets('elige el elemento del nivel por nombre y emite su id', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fuente = _FuenteFalsa();
    final emitidas = <AmbitoSeleccion>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmbitoSelector(
            fuente: fuente,
            seleccionActual: const AmbitoSeleccion(
              nivel: 'GLOBAL',
              nivelId: '',
            ),
            onChanged: emitidas.add,
          ),
        ),
      ),
    );
    expect(find.text('No aplica (Global)'), findsOneWidget);

    await tester.tap(find.text('Global (sistema)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sede').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byWidgetPredicate((w) => w is SelectorBusqueda));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'norte');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('CEN · Sede Centro'), findsNothing);
    await tester.tap(find.text('NOR · Sede Norte'));
    await tester.pumpAndSettle();

    expect(fuente.niveles, ['SEDE']); // se carga una sola vez por nivel
    expect(emitidas.single.nivel, 'SEDE');
    expect(emitidas.single.sedeId, 's-2');
  });

  testWidgets('muestra la etiqueta del ámbito ya seleccionado', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmbitoSelector(
            fuente: _FuenteFalsa(),
            seleccionActual: const AmbitoSeleccion(
              nivel: 'SEDE',
              nivelId: 's-1',
            ),
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('CEN · Sede Centro'), findsOneWidget);
    expect(find.text('s-1'), findsNothing);
  });
}
