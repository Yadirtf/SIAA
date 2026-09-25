import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/geo_editor/data/espacio_repository.dart';
import 'package:siaa_mobile/features/home/presentation/widgets/panels/jerarquia_selector_panel.dart';

void main() {
  testWidgets('DropdownButtonFormField fails if SedeModel does not implement ==', (tester) async {
    final s1 = SedeModel(id: 's1', codigo: 'S1', nombre: 'Sede Principal');
    final s2 = SedeModel(id: 's1', codigo: 'S1', nombre: 'Sede Principal');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JerarquiaSelectorPanel(
            isDark: false,
            sedes: [s1],
            sedeSeleccionada: s2, // Distinct instance with same id!
            cargandoSedes: false,
            onSedeChanged: (_) {},
            onNuevaSede: () {},
            bloques: const [],
            bloqueSeleccionado: null,
            cargandoBloques: false,
            onBloqueChanged: (_) {},
            onNuevoBloque: () {},
            espacios: const [],
            cargandoEspacios: false,
            onCrearAula: () {},
            onEditarEspacio: (_) {},
          ),
        ),
      ),
    );

    final exception = tester.takeException();
    print('EXCEPTION CAUGHT: $exception');
    expect(exception, isNull);
  });
}
