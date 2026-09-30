// nav_config.dart - Modulo de exportacion y compatibilidad de navegacion (SIAA Movil)
// Re-exporta los modelos, catalogos y servicios desacoplados del sistema de navegacion.
export 'config/app_routes.dart';
export 'config/nav_destinations.dart';
export 'config/role_navigation_matrix.dart';
export 'domain/models/nav_item.dart';
export 'domain/models/rol_nav_config.dart';
export 'domain/services/nav_permission_service.dart';

import 'config/nav_destinations.dart';
import 'config/role_navigation_matrix.dart';
import 'domain/models/nav_item.dart';
import 'domain/models/rol_nav_config.dart';
import 'domain/services/nav_permission_service.dart';

/// Alias de compatibilidad hacia [NavDestinations].
typedef NavItems = NavDestinations;

/// Alias de compatibilidad hacia [kRoleNavigationMatrix].
const Map<String, RolNavConfig> kRolNavConfigs = kRoleNavigationMatrix;

/// Helper global de compatibilidad hacia [NavPermissionService.filtrarPorPermisos].
List<NavItem> filtrarPorPermisos(
  List<NavItem> items,
  List<String> permisosUsuario,
) {
  return const NavPermissionService()
      .filtrarPorPermisos(items, permisosUsuario);
}

/// Helper global de compatibilidad hacia [NavPermissionService.configParaRol].
RolNavConfig? configParaRol(String rolSlug) {
  return const NavPermissionService().configParaRol(rolSlug);
}
