// nav_permission_service.dart - Servicio de filtrado RBAC para navegacion (SIAA Movil)
// RF-ROL-001, RF-ROL-003, RF-ROL-004
// El cliente NO calcula permisos; solo filtra destinos contra la lista autorizada por backend.
import '../../config/role_navigation_matrix.dart';
import '../models/nav_item.dart';
import '../models/rol_nav_config.dart';

/// Servicio de dominio encargado de resolver la configuracion de navegacion
/// activa y filtrar destinos permitidos segun los permisos RBAC reales.
class NavPermissionService {
  const NavPermissionService();

  /// Filtra una lista de destinos [items] contrastandolos con [permisosUsuario].
  /// Si el destino tiene `permiso == null`, es publico y siempre se incluye.
  List<NavItem> filtrarPorPermisos(
    List<NavItem> items,
    List<String> permisosUsuario,
  ) {
    return items.where((item) {
      if (item.permiso == null) return true;
      return permisosUsuario.contains(item.permiso);
    }).toList();
  }

  /// Retorna la [RolNavConfig] configurada para [rolSlug] (case-insensitive).
  RolNavConfig? configParaRol(String rolSlug) {
    return kRoleNavigationMatrix[rolSlug.toLowerCase()];
  }

  /// Encuentra el primer rol valido dentro de la lista de roles del usuario.
  String primerRolConConfig(List<String> roles) {
    for (final r in roles) {
      if (kRoleNavigationMatrix.containsKey(r.toLowerCase())) {
        return r.toLowerCase();
      }
    }
    return roles.isNotEmpty ? roles.first.toLowerCase() : 'docente';
  }

  /// Resuelve la tupla (bottomItems, drawerExtraItems) para un rol y permisos dados.
  (List<NavItem>, List<NavItem>) resolverNavegacion(
    String rolSlug,
    List<String> permisos,
  ) {
    final config = configParaRol(rolSlug);
    if (config == null) return (const [], const []);
    return (
      filtrarPorPermisos(config.bottomItems, permisos),
      filtrarPorPermisos(config.drawerExtraItems, permisos),
    );
  }
}
