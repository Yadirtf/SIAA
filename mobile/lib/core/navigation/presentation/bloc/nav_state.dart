// nav_state.dart - Estado inmutable de navegacion (SIAA Movil)
// RF-ROL-001, RF-ROL-004
import 'package:equatable/equatable.dart';
import '../../domain/models/nav_item.dart';

class NavState extends Equatable {
  final List<String> rolesDisponibles;
  final List<String> permisosUsuario;
  final String rolActivo;
  final List<NavItem> bottomItems;
  final List<NavItem> drawerExtraItems;
  final int tabIndex;

  /// Ruta activa cuando el destino proviene del drawer (null = usa tabIndex del bottom).
  final String? activeDrawerRoute;

  const NavState({
    this.rolesDisponibles = const [],
    this.permisosUsuario = const [],
    this.rolActivo = 'docente',
    this.bottomItems = const [],
    this.drawerExtraItems = const [],
    this.tabIndex = 0,
    this.activeDrawerRoute,
  });

  NavState copyWith({
    List<String>? rolesDisponibles,
    List<String>? permisosUsuario,
    String? rolActivo,
    List<NavItem>? bottomItems,
    List<NavItem>? drawerExtraItems,
    int? tabIndex,
    String? activeDrawerRoute,
    bool clearDrawerRoute = false,
  }) {
    return NavState(
      rolesDisponibles: rolesDisponibles ?? this.rolesDisponibles,
      permisosUsuario: permisosUsuario ?? this.permisosUsuario,
      rolActivo: rolActivo ?? this.rolActivo,
      bottomItems: bottomItems ?? this.bottomItems,
      drawerExtraItems: drawerExtraItems ?? this.drawerExtraItems,
      tabIndex: tabIndex ?? this.tabIndex,
      activeDrawerRoute: clearDrawerRoute
          ? null
          : (activeDrawerRoute ?? this.activeDrawerRoute),
    );
  }

  @override
  List<Object?> get props => [
        rolesDisponibles,
        permisosUsuario,
        rolActivo,
        bottomItems,
        drawerExtraItems,
        tabIndex,
        activeDrawerRoute,
      ];
}
