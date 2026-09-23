import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/dashboard/data/admin_geo_repository.dart';
import 'package:siaa_web/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:siaa_web/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:siaa_web/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:siaa_web/features/dashboard/presentation/widgets/cards/dashboard_stat_card.dart';
import 'package:siaa_web/features/dashboard/presentation/widgets/sidebar/dashboard_sidebar.dart';

class MockAdminGeoRepository extends AdminGeoRepository {
  @override
  Future<List<AdminSede>> listarSedes() async => [
        const AdminSede(id: 's1', codigo: 'SED-01', nombre: 'Sede Central', activo: true),
      ];

  @override
  Future<List<AdminBloque>> listarBloques({String? sedeId}) async => [
        const AdminBloque(id: 'b1', sedeId: 's1', codigo: 'BLOQ-A', nombre: 'Bloque A', pisos: [1, 2], activo: true),
      ];

  @override
  Future<List<AdminEspacio>> listarEspacios({
    String? sedeId,
    String? bloqueId,
    String? tipo,
    String? estado,
  }) async => [
        const AdminEspacio(
          id: 'e1',
          sedeId: 's1',
          codigo: 'AULA-101',
          nombre: 'Aula 101',
          capacidad: 30,
          tipo: 'AULA',
          estado: 'ACTIVO',
          nivelValidacion: 'AULA',
          bufferMetros: 10,
          areaMetrosCuadrados: 54.0,
          tieneGeometria: true,
          versionGeometria: 1,
          activo: true,
        ),
      ];
}

void main() {
  group('Piezas del Rompecabezas Web Dashboard', () {
    testWidgets('DashboardStatCard: renderiza título, valor e icono con formato', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                DashboardStatCard(
                  title: 'Total Espacios',
                  value: '42',
                  icon: Icons.meeting_room,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Total Espacios'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(Icons.meeting_room), findsOneWidget);
    });

    testWidgets('DashboardSidebar: renderiza items de navegación y emite índice al seleccionar', (tester) async {
      int selectedNav = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardSidebar(
              selectedNavIndex: selectedNav,
              onNavItemSelected: (index) => selectedNav = index,
            ),
          ),
        ),
      );

      expect(find.text('SIAA'), findsOneWidget);
      expect(find.text('Consola Admin'), findsOneWidget);
      expect(find.text('Aulas y Espacios'), findsOneWidget);
      expect(find.text('Sedes y Bloques'), findsOneWidget);
      expect(find.text('Periodos Lectivos'), findsOneWidget);

      await tester.tap(find.text('Periodos Lectivos'));
      await tester.pump();

      expect(selectedNav, equals(2));
    });

    test('DashboardBloc: CargarDatosRequested emite estado success con colecciones', () async {
      final mockRepo = MockAdminGeoRepository();
      final bloc = DashboardBloc(geoRepo: mockRepo);

      expect(bloc.state.status, equals(DashboardStatus.initial));

      bloc.add(const DashboardCargarDatosRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<DashboardState>((s) => s.status == DashboardStatus.loading),
          predicate<DashboardState>((s) =>
              s.status == DashboardStatus.success &&
              s.sedes.length == 1 &&
              s.bloques.length == 1 &&
              s.espacios.length == 1 &&
              s.delimitadosCount == 1),
        ]),
      );

      await bloc.close();
    });
  });
}
