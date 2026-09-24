// rol_nav_config.dart - Entidad de configuracion de navegacion por rol (SIAA Movil)
// RF-ROL-001, RF-ROL-004
import 'package:equatable/equatable.dart';
import 'nav_item.dart';

/// Define los destinos de navegacion asignados a un rol especifico.
class RolNavConfig extends Equatable {
  final String rolSlug;
  final String rolLabel;
  final List<NavItem> bottomItems;
  final List<NavItem> drawerExtraItems;

  const RolNavConfig({
    required this.rolSlug,
    required this.rolLabel,
    required this.bottomItems,
    this.drawerExtraItems = const [],
  });

  @override
  List<Object?> get props => [rolSlug, rolLabel, bottomItems, drawerExtraItems];
}
