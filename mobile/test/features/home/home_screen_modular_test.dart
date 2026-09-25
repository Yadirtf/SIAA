import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/geo_editor/data/espacio_repository.dart';
import 'package:siaa_mobile/features/home/presentation/widgets/cards/espacio_card_tile.dart';
import 'package:siaa_mobile/features/home/presentation/widgets/cards/user_profile_card.dart';
import 'package:siaa_mobile/features/home/presentation/widgets/panels/modulos_secundarios_panel.dart';

void main() {
  group('Piezas del Rompecabezas HomeScreen (Pruebas Modulares)', () {
    testWidgets('UserProfileCard: renderiza nombre, inicial y chips de rol',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserProfileCard(
              nombre: 'Carlos Perez',
              roles: ['Coordinador', 'Docente'],
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('Carlos Perez'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('Coordinador'), findsOneWidget);
      expect(find.text('Docente'), findsOneWidget);
    });

    testWidgets(
        'EspacioCardTile: muestra estado delimitado con área y ejecuta callback',
        (tester) async {
      bool editado = false;
      const espacio = EspacioModel(
        id: 'esp-01',
        sedeId: 'sede-01',
        codigo: 'A-201',
        nombre: 'Laboratorio de Redes',
        capacidad: 25,
        tipo: 'LABORATORIO',
        estado: 'ACTIVO',
        nivelValidacion: 'AULA',
        bufferMetros: 10.0,
        areaMetrosCuadrados: 65.5,
        tieneGeometria: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EspacioCardTile(
              espacio: espacio,
              onEditarPoligono: () => editado = true,
            ),
          ),
        ),
      );

      expect(find.text('A-201'), findsOneWidget);
      expect(find.text('Laboratorio de Redes'), findsOneWidget);
      expect(find.text('Delimitada (65.5 m²)'), findsOneWidget);
      expect(find.text('Editar Polígono'), findsOneWidget);

      await tester.tap(find.text('Editar Polígono'));
      await tester.pump();
      expect(editado, isTrue);
    });

    testWidgets(
        'ModulosSecundariosPanel: renderiza accesos a módulos con badges de pronto',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModulosSecundariosPanel(isDark: false),
          ),
        ),
      );

      expect(find.text('Marcaje de Asistencia'), findsOneWidget);
      expect(find.text('Historial de Asistencia'), findsOneWidget);
      expect(find.text('Pronto'), findsNWidgets(2));
    });
  });
}
