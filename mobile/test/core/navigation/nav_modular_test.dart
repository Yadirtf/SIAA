// nav_modular_test.dart - Pruebas unitarias y de widgets para las piezas modulares de navegacion
// RF-ROL-001, RF-ROL-003, RF-ROL-004
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/navigation/navigation.dart';
import 'package:siaa_mobile/core/navigation/presentation/widgets/drawer/drawer_nav_item_tile.dart';
import 'package:siaa_mobile/core/navigation/presentation/widgets/drawer/drawer_user_header.dart';
import 'package:siaa_mobile/core/navigation/presentation/widgets/drawer/role_context_selector.dart';

void main() {
  group(
      'Piezas del Rompecabezas Navegacion: NavPermissionService (Dominio / RBAC)',
      () {
    const service = NavPermissionService();

    test(
        'filtrarPorPermisos permite items sin permiso y filtra los que no estan en la lista',
        () {
      final items = [
        NavDestinations.inicio, // requiere 'marcaje:crear'
        NavDestinations.miHorario, // permiso null (publico)
        NavDestinations.reportes, // requiere 'reporte:exportar'
      ];

      final resultado = service.filtrarPorPermisos(items, ['marcaje:crear']);

      expect(resultado.length, 2);
      expect(resultado, contains(NavDestinations.inicio));
      expect(resultado, contains(NavDestinations.miHorario));
      expect(resultado.contains(NavDestinations.reportes), isFalse);
    });

    test('configParaRol resuelve configuracion correcta para roles soportados',
        () {
      final configDocente = service.configParaRol('docente');
      expect(configDocente, isNotNull);
      expect(configDocente!.rolLabel, 'Docente');
      expect(configDocente.bottomItems.length, 4);

      final configAdmin = service.configParaRol('admin');
      expect(configAdmin, isNotNull);
      expect(configAdmin!.rolLabel, 'Administrador');
      expect(configAdmin.bottomItems.length, 3);
      expect(configAdmin.drawerExtraItems.length, 3);
    });

    test('primerRolConConfig selecciona el primer rol que posee configuracion',
        () {
      final rol =
          service.primerRolConConfig(['ROL_INEXISTENTE', 'ADMIN', 'DOCENTE']);
      expect(rol, 'admin');
    });

    test(
        'resolverNavegacion filtra bottom y drawer segun permisos reales del backend',
        () {
      final (bottom, drawer) =
          service.resolverNavegacion('admin', ['aula:leer']);

      // Admin tiene en bottom: espacios (aula:leer), editorGps (aula:editar-geometria), marcajesAdmin (marcaje:anular)
      expect(bottom.length, 1);
      expect(bottom.first, NavDestinations.espacios);

      // Admin tiene en drawer: solapamientos (aula:leer), reportes (reporte:exportar), justificacionesAprobar (justificacion:aprobar)
      expect(drawer.length, 1);
      expect(drawer.first, NavDestinations.solapamientos);
    });
  });

  group('Piezas del Rompecabezas Navegacion: NavBloc (Gestion de Estado)', () {
    late NavBloc bloc;

    setUp(() {
      bloc = NavBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test(
        'NavInicializado inicializa el estado con el primer rol y resuelve destinos',
        () async {
      bloc.add(const NavInicializado(
        rolesUsuario: ['docente'],
        permisosUsuario: ['marcaje:crear', 'marcaje:leer'],
      ));

      await expectLater(
        bloc.stream,
        emits(predicate<NavState>((state) {
          return state.rolActivo == 'docente' &&
              state.rolesDisponibles.contains('docente') &&
              state.bottomItems.contains(NavDestinations.inicio) &&
              state.bottomItems.contains(NavDestinations.miHorario) &&
              state.tabIndex == 0;
        })),
      );
    });

    test(
        'NavContextoCambiado alterna entre roles sin perder la sesion (RF-ROL-004)',
        () async {
      bloc.add(const NavInicializado(
        rolesUsuario: ['docente', 'admin'],
        permisosUsuario: [
          'marcaje:crear',
          'aula:leer',
          'aula:editar-geometria',
          'marcaje:anular'
        ],
      ));

      await bloc.stream.first;

      bloc.add(const NavContextoCambiado('admin'));

      await expectLater(
        bloc.stream,
        emits(predicate<NavState>((state) {
          return state.rolActivo == 'admin' &&
              state.bottomItems.contains(NavDestinations.espacios) &&
              state.bottomItems.contains(NavDestinations.editorGps);
        })),
      );
    });

    test('NavTabCambiado actualiza tabIndex y limpia drawer route', () async {
      bloc.add(const NavTabCambiado(2));

      await expectLater(
        bloc.stream,
        emits(predicate<NavState>((state) {
          return state.tabIndex == 2 && state.activeDrawerRoute == null;
        })),
      );
    });

    test('NavDrawerItemSelected establece activeDrawerRoute', () async {
      bloc.add(const NavDrawerItemSelected('/shell/perfil'));

      await expectLater(
        bloc.stream,
        emits(predicate<NavState>((state) {
          return state.activeDrawerRoute == '/shell/perfil';
        })),
      );
    });
  });

  group('Piezas del Rompecabezas Navegacion: Widgets Atomicos', () {
    testWidgets('AppShellAppBar renderiza titulo SIAA y chip de rol',
        (tester) async {
      const state = NavState(rolActivo: 'docente');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppShellAppBar(navState: state),
          ),
        ),
      );

      expect(find.text('SIAA'), findsOneWidget);
      expect(find.text('Docente'), findsOneWidget);
    });

    testWidgets('AppBottomNavBar renderiza items y dispara callback al tocar',
        (tester) async {
      int tappedIndex = -1;
      final items = [
        NavDestinations.inicio,
        NavDestinations.miHorario,
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(
              items: items,
              currentIndex: 0,
              onTap: (i) => tappedIndex = i,
            ),
          ),
        ),
      );

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Horario'), findsOneWidget);

      await tester.tap(find.text('Horario'));
      expect(tappedIndex, 1);
    });

    testWidgets('DrawerUserHeader muestra inicial del nombre y nombre completo',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DrawerUserHeader(nombre: 'Carlos Perez'),
          ),
        ),
      );

      expect(find.text('C'), findsOneWidget);
      expect(find.text('Carlos Perez'), findsOneWidget);
    });

    testWidgets(
        'RoleContextSelector no se muestra si el usuario tiene solo un rol',
        (tester) async {
      const state =
          NavState(rolesDisponibles: ['docente'], rolActivo: 'docente');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoleContextSelector(navState: state),
          ),
        ),
      );

      expect(find.text('CONTEXTO ACTIVO'), findsNothing);
    });

    testWidgets(
        'RoleContextSelector se muestra cuando hay multiples roles (RF-ROL-004)',
        (tester) async {
      const state = NavState(
        rolesDisponibles: ['docente', 'coordinador'],
        rolActivo: 'docente',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoleContextSelector(navState: state),
          ),
        ),
      );

      expect(find.text('CONTEXTO ACTIVO'), findsOneWidget);
      expect(find.text('Docente'), findsOneWidget);
    });

    testWidgets('DrawerNavItemTile renderiza titulo y responde al tap',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawerNavItemTile(
              item: NavDestinations.perfil,
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Perfil'), findsOneWidget);
      await tester.tap(find.text('Perfil'));
      expect(tapped, isTrue);
    });
  });
}
