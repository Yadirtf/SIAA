// nav_destinations.dart - Catalogo global de destinos de navegacion (SIAA Movil)
// RF-ROL-001, RF-ROL-003, RF-ROL-004
import 'package:flutter/material.dart';
import '../domain/models/nav_item.dart';

/// Catalogo estatico y centralizado de todos los destinos de navegacion en SIAA Movil.
/// Para registrar una nueva pantalla en el sistema, anade una constante aqui.
class NavDestinations {
  NavDestinations._();

  static const inicio = NavItem(
    label: 'Inicio',
    icon: Icons.touch_app_outlined,
    iconSelected: Icons.touch_app_rounded,
    route: '/shell/inicio',
    permiso: 'marcaje:crear',
  );

  static const historial = NavItem(
    label: 'Historial',
    icon: Icons.history_outlined,
    iconSelected: Icons.history_rounded,
    route: '/shell/historial',
    permiso: 'marcaje:leer',
  );

  static const miHorario = NavItem(
    label: 'Horario',
    icon: Icons.calendar_today_outlined,
    iconSelected: Icons.calendar_today_rounded,
    route: '/shell/horario',
    permiso: null,
  );

  static const justificaciones = NavItem(
    label: 'Justificar',
    icon: Icons.edit_note_outlined,
    iconSelected: Icons.edit_note_rounded,
    route: '/shell/justificaciones',
    permiso: 'justificacion:crear',
  );

  static const espacios = NavItem(
    label: 'Espacios',
    icon: Icons.business_outlined,
    iconSelected: Icons.business_rounded,
    route: '/shell/espacios',
    permiso: 'aula:leer',
  );

  static const editorGps = NavItem(
    label: 'Editor GPS',
    icon: Icons.map_outlined,
    iconSelected: Icons.map_rounded,
    route: '/shell/editor-gps',
    permiso: 'aula:editar-geometria',
  );

  static const marcajesAdmin = NavItem(
    label: 'Marcajes',
    icon: Icons.manage_search_outlined,
    iconSelected: Icons.manage_search_rounded,
    route: '/shell/marcajes-admin',
    permiso: 'marcaje:anular',
  );

  static const reportes = NavItem(
    label: 'Reportes',
    icon: Icons.bar_chart_outlined,
    iconSelected: Icons.bar_chart_rounded,
    route: '/shell/reportes',
    permiso: 'reporte:exportar',
  );

  static const justificacionesAprobar = NavItem(
    label: 'Revision',
    icon: Icons.fact_check_outlined,
    iconSelected: Icons.fact_check_rounded,
    route: '/shell/aprobar-justificaciones',
    permiso: 'justificacion:aprobar',
  );

  static const solapamientos = NavItem(
    label: 'Solapamientos',
    icon: Icons.layers_outlined,
    iconSelected: Icons.layers_rounded,
    route: '/shell/solapamientos',
    permiso: 'aula:leer',
  );

  static const marcajeGrupal = NavItem(
    label: 'Marcaje grupal',
    icon: Icons.group_outlined,
    iconSelected: Icons.group_rounded,
    route: '/shell/marcaje-grupal',
    permiso: 'marcaje:crear',
  );

  // Destinos comunes (siempre presentes en Drawer, no en BottomBar)
  static const perfil = NavItem(
    label: 'Perfil',
    icon: Icons.person_outline_rounded,
    iconSelected: Icons.person_rounded,
    route: '/shell/perfil',
    permiso: null,
  );

  static const privacidad = NavItem(
    label: 'Aviso de privacidad',
    icon: Icons.privacy_tip_outlined,
    iconSelected: Icons.privacy_tip_rounded,
    route: '/shell/privacidad',
    permiso: null,
  );
}
