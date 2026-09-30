import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/widgets/selector_busqueda.dart';
import 'package:siaa_web/features/dispositivos/presentation/widgets/dispositivo_busqueda_bar.dart';
import 'package:siaa_web/features/usuarios/data/buscador_usuarios.dart';

import '../../academico/fake_catalogos.dart';

void main() {
  testWidgets('consulta los dispositivos del usuario elegido por nombre', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final usuarios = FakeBuscadorUsuarios([
      docente('usr-1', 'Ana', 'Pérez'),
      docente('usr-2', 'Bruno', 'Díaz'),
    ]);
    final consultados = <String>[];
    await tester.pumpWidget(
      RepositoryProvider<BuscadorUsuarios>.value(
        value: usuarios,
        child: MaterialApp(
          home: Scaffold(
            body: DispositivoBusquedaBar(
              usuarioIdInicial: 'usr-1',
              onBuscarUsuario: consultados.add,
              onRecargar: () {},
              onCambiarFiltro: (_) {},
              filtroActual: DispositivoFiltro.todos,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // El id inicial se muestra con el nombre, nunca como id.
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.textContaining('usr-1'), findsNothing);

    await tester.tap(find.byWidgetPredicate((w) => w is SelectorBusqueda));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bruno Díaz'));
    await tester.pumpAndSettle();

    expect(consultados, ['usr-2']);
  });
}
