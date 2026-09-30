import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/widgets/selector_busqueda.dart';

class _Persona {
  final String id;
  final String nombre;
  const _Persona(this.id, this.nombre);
}

const _personas = [
  _Persona('u-1', 'Ana Pérez'),
  _Persona('u-2', 'Bruno Díaz'),
  _Persona('u-3', 'Carla Ruiz'),
];

final _selector = find.byWidgetPredicate((w) => w is SelectorBusqueda);

void main() {
  late List<String> consultas;
  late List<String?> cambios;
  final formKey = GlobalKey<FormState>();

  Future<List<_Persona>> buscar(String q) async {
    consultas.add(q);
    return _personas
        .where((p) => p.nombre.toLowerCase().contains(q.toLowerCase()))
        .toList();
  }

  Widget app({String? idInicial, bool requerido = false}) => MaterialApp(
    home: Scaffold(
      body: Form(
        key: formKey,
        child: SelectorBusqueda<_Persona>(
          etiqueta: 'Docente *',
          buscar: buscar,
          resolver: (id) async =>
              _personas.where((p) => p.id == id).firstOrNull,
          textoDe: (p) => p.nombre,
          idDe: (p) => p.id,
          idInicial: idInicial,
          requerido: requerido,
          onCambio: (p) => cambios.add(p?.id),
        ),
      ),
    ),
  );

  setUp(() {
    consultas = [];
    cambios = [];
  });

  testWidgets('abre la búsqueda, consulta con espera y selecciona', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(_selector);
    await tester.pumpAndSettle();

    // Al abrir consulta con texto vacío y muestra las primeras opciones.
    expect(consultas, ['']);
    expect(find.text('Bruno Díaz'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'car');
    await tester.pump(const Duration(milliseconds: 100));
    expect(consultas, ['']); // aún dentro de la espera (debounce)
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(consultas, ['', 'car']);
    expect(find.text('Bruno Díaz'), findsNothing);

    await tester.tap(find.text('Carla Ruiz'));
    await tester.pumpAndSettle();

    expect(cambios, ['u-3']);
    expect(find.text('Carla Ruiz'), findsOneWidget);
    expect(find.text('u-3'), findsNothing); // nunca muestra el id
  });

  testWidgets('muestra "Sin resultados" cuando no hay coincidencias', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(_selector);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Sin resultados'), findsOneWidget);
  });

  testWidgets('resuelve la etiqueta de un id inicial y permite limpiarlo', (
    tester,
  ) async {
    await tester.pumpWidget(app(idInicial: 'u-2'));
    await tester.pumpAndSettle();
    expect(find.text('Bruno Díaz'), findsOneWidget);

    await tester.tap(find.byTooltip('Quitar selección'));
    await tester.pumpAndSettle();
    expect(find.text('Bruno Díaz'), findsNothing);
    expect(cambios, [null]);
  });

  testWidgets('valida el campo requerido y limpia el error al elegir', (
    tester,
  ) async {
    await tester.pumpWidget(app(requerido: true));
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Requerido'), findsOneWidget);

    await tester.tap(_selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Pérez'));
    await tester.pumpAndSettle();

    expect(find.text('Requerido'), findsNothing);
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('descarta respuestas viejas que llegan tarde', (tester) async {
    final lenta = Completer<List<_Persona>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectorBusqueda<_Persona>(
            etiqueta: 'Docente',
            espera: Duration.zero,
            buscar: (q) => q == 'a' ? lenta.future : buscar(q),
            textoDe: (p) => p.nombre,
            idDe: (p) => p.id,
            onCambio: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(_selector);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'bruno');
    await tester.pumpAndSettle();
    lenta.complete(_personas);
    await tester.pumpAndSettle();

    expect(find.text('Bruno Díaz'), findsOneWidget);
    expect(find.text('Ana Pérez'), findsNothing);
  });
}
