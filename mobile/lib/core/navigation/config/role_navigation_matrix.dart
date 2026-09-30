// role_navigation_matrix.dart - Matriz de destinos por rol (SIAA Movil)
// RF-ROL-001, RF-ROL-003, RF-ROL-004
// Linea base segun SRS SIAA-SRS-001 seccion 2.3 y 3.2. Cada destino se filtra ademas por
// el permiso que exige su endpoint, de modo que ningun item lleve a un 403.
// Las claves son slugs (ver rol_slug.dart: ADMIN_INSTITUCIONAL -> admin).
import '../domain/models/rol_nav_config.dart';
import 'nav_destinations.dart';

/// Matriz estatica que define los destinos de BottomNavigation y Drawer para cada rol.
const Map<String, RolNavConfig> kRoleNavigationMatrix = {
  // Docente: Bottom (Inicio > Horario > Historial > Justificar)
  // Drawer: marcaje grupal de estudiantes (US-MAR-13/14, lo abre el docente de la sesion)
  'docente': RolNavConfig(
    rolSlug: 'docente',
    rolLabel: 'Docente',
    bottomItems: [
      NavDestinations.inicio,
      NavDestinations.miHorario,
      NavDestinations.historial,
      NavDestinations.justificaciones,
    ],
    drawerExtraItems: [
      NavDestinations.marcajeGrupal,
    ],
  ),

  // Estudiante: Bottom (Inicio > Horario > Historial). No radica justificaciones
  // (sin justificacion:crear en §3.2).
  'estudiante': RolNavConfig(
    rolSlug: 'estudiante',
    rolLabel: 'Estudiante',
    bottomItems: [
      NavDestinations.inicio,
      NavDestinations.miHorario,
      NavDestinations.historial,
    ],
  ),

  // Administrador: Bottom (Espacios > Editor GPS > Marcajes)
  // Drawer: Solapamientos, Reportes, Revision de Justificaciones, Parametros
  'admin': RolNavConfig(
    rolSlug: 'admin',
    rolLabel: 'Administrador',
    bottomItems: [
      NavDestinations.espacios,
      NavDestinations.editorGps,
      NavDestinations.marcajesAdmin,
    ],
    drawerExtraItems: [
      NavDestinations.solapamientos,
      NavDestinations.reportes,
      NavDestinations.justificacionesAprobar,
      NavDestinations.parametros,
    ],
  ),

  // Superadministrador: Vista global
  'superadmin': RolNavConfig(
    rolSlug: 'superadmin',
    rolLabel: 'Superadministrador',
    bottomItems: [
      NavDestinations.espacios,
      NavDestinations.editorGps,
      NavDestinations.marcajesAdmin,
      NavDestinations.reportes,
    ],
    drawerExtraItems: [
      NavDestinations.solapamientos,
      NavDestinations.justificacionesAprobar,
      NavDestinations.parametros,
    ],
  ),

  // Coordinador: revisiones, marcajes y reportes de su ambito (§3.2)
  'coordinador': RolNavConfig(
    rolSlug: 'coordinador',
    rolLabel: 'Coordinador',
    bottomItems: [
      NavDestinations.marcajesAdmin,
      NavDestinations.justificacionesAprobar,
      NavDestinations.reportes,
    ],
    drawerExtraItems: [
      NavDestinations.espacios,
      NavDestinations.solapamientos,
      NavDestinations.parametros,
    ],
  ),

  // Monitor / Auxiliar: consulta de marcajes y reportes de su ambito. El backend no le
  // concede marcaje:crear (§3.2), por eso el marcaje grupal lo opera el docente.
  'monitor': RolNavConfig(
    rolSlug: 'monitor',
    rolLabel: 'Monitor / Auxiliar',
    bottomItems: [
      NavDestinations.marcajesAdmin,
      NavDestinations.reportes,
    ],
  ),

  // Auditor: inspeccion y trazabilidad (solo lectura)
  'auditor': RolNavConfig(
    rolSlug: 'auditor',
    rolLabel: 'Auditor',
    bottomItems: [
      NavDestinations.marcajesAdmin,
      NavDestinations.reportes,
      NavDestinations.espacios,
    ],
    drawerExtraItems: [
      NavDestinations.solapamientos,
    ],
  ),
};
