// role_navigation_matrix.dart - Matriz de destinos por rol (SIAA Movil)
// RF-ROL-001, RF-ROL-003, RF-ROL-004
// Linea base segun SRS SIAA-SRS-001 seccion 2.3 y 3.2
import '../domain/models/rol_nav_config.dart';
import 'nav_destinations.dart';

/// Matriz estatica que define los destinos de BottomNavigation y Drawer para cada rol.
const Map<String, RolNavConfig> kRoleNavigationMatrix = {
  // Docente: Bottom (Inicio > Horario > Historial > Justificar)
  'docente': RolNavConfig(
    rolSlug: 'docente',
    rolLabel: 'Docente',
    bottomItems: [
      NavDestinations.inicio,
      NavDestinations.miHorario,
      NavDestinations.historial,
      NavDestinations.justificaciones,
    ],
  ),

  // Estudiante: Bottom (Inicio > Horario > Historial > Justificar)
  'estudiante': RolNavConfig(
    rolSlug: 'estudiante',
    rolLabel: 'Estudiante',
    bottomItems: [
      NavDestinations.inicio,
      NavDestinations.miHorario,
      NavDestinations.historial,
      NavDestinations.justificaciones,
    ],
  ),

  // Administrador: Bottom (Espacios > Editor GPS > Marcajes)
  // Drawer: Solapamientos, Reportes, Revision de Justificaciones
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
    ],
  ),

  // Coordinador: Foco en revisiones y reportes
  'coordinador': RolNavConfig(
    rolSlug: 'coordinador',
    rolLabel: 'Coordinador',
    bottomItems: [
      NavDestinations.marcajesAdmin,
      NavDestinations.justificacionesAprobar,
      NavDestinations.reportes,
    ],
  ),

  // Monitor / Auxiliar: Marcaje grupal y consulta
  'monitor': RolNavConfig(
    rolSlug: 'monitor',
    rolLabel: 'Monitor / Auxiliar',
    bottomItems: [
      NavDestinations.marcajeGrupal,
      NavDestinations.historial,
    ],
  ),

  // Auditor: Inspeccion y trazabilidad
  'auditor': RolNavConfig(
    rolSlug: 'auditor',
    rolLabel: 'Auditor',
    bottomItems: [
      NavDestinations.reportes,
    ],
  ),
};
