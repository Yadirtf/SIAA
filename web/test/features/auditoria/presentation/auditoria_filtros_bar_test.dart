import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/widgets/selector_busqueda.dart';
import 'package:siaa_web/features/auditoria/data/models/filtro_auditoria_model.dart';
import 'package:siaa_web/features/auditoria/presentation/widgets/auditoria_filtros_bar.dart';
import 'package:siaa_web/features/usuarios/data/buscador_usuarios.dart';

import '../../academico/fake_catalogos.dart';

void main() {
  testWidgets('el actor se elige por nombre y filtra por su id', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final usuarios = FakeBuscadorUsuarios([
      docente('adm-1', 'Admin', 'General'),
    ]);
    final filtros = <FiltroAuditoriaModel>[];
    await tester.pumpWidget(
      RepositoryProvider<BuscadorUsuarios>.value(
        value: usuarios,
        child: MaterialApp(
          home: Scaffold(
            body: AuditoriaFiltrosBar(
              filtro: const FiltroAuditoriaModel(),
              onFiltrar: filtros.add,
              onRecargar: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('ID de la entidad (avanzado)'), findsOneWidget);
    expect(find.text('Id del actor'), findsNothing);

    await tester.tap(find.byWidgetPredicate((w) => w is SelectorBusqueda));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin General'));
    await tester.pumpAndSettle();

    expect(filtros.single.actorId, 'adm-1');
    expect(filtros.single.pagina, 1);
  });
}
