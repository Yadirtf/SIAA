import 'package:flutter/material.dart';

enum NavSection {
  inicio,
  sedes,
  bloques,
  espacios,
  solapamientos,
  periodos,
  estructura,
  asignaciones,
  sesiones,
  excepciones,
  dispositivos,

  parametros,
  marcajes,
  justificaciones,
  reportes,
  tablero,
  ocupacion,
  asistenciaEstudiantil,
  usuarios,
  auditoria,
  privacidad,
}

class NavItem {
  final NavSection section;
  final String title;
  final IconData icon;
  final String category;

  /// Permiso RBAC requerido para mostrar la entrada (null = siempre visible).
  final String? permiso;

  const NavItem({
    required this.section,
    required this.title,
    required this.icon,
    required this.category,
    this.permiso,
  });

  /// Entradas visibles para un usuario con los [permisos] indicados.
  static List<NavItem> visiblesPara(List<String> permisos) => items
      .where((i) => i.permiso == null || permisos.contains(i.permiso))
      .toList();

  static const List<NavItem> items = [
    NavItem(
      section: NavSection.inicio,
      title: 'Panel General',
      icon: Icons.dashboard_outlined,
      category: 'PRINCIPAL',
    ),
    NavItem(
      section: NavSection.sedes,
      title: 'Sedes',
      icon: Icons.domain_rounded,
      category: 'INFRAESTRUCTURA',
    ),
    NavItem(
      section: NavSection.bloques,
      title: 'Bloques',
      icon: Icons.apartment_rounded,
      category: 'INFRAESTRUCTURA',
    ),
    NavItem(
      section: NavSection.espacios,
      title: 'Espacios y Aulas',
      icon: Icons.meeting_room_outlined,
      category: 'INFRAESTRUCTURA',
    ),
    NavItem(
      section: NavSection.solapamientos,
      title: 'Control Solapamientos',
      icon: Icons.layers_outlined,
      category: 'INFRAESTRUCTURA',
    ),
    NavItem(
      section: NavSection.periodos,
      title: 'Periodos Académicos',
      icon: Icons.calendar_month_outlined,
      category: 'ACADÉMICO',
    ),
    NavItem(
      section: NavSection.estructura,
      title: 'Estructura Académica',
      icon: Icons.account_tree_outlined,
      category: 'ACADÉMICO',
    ),
    NavItem(
      section: NavSection.asignaciones,
      title: 'Asignaciones Horarias',
      icon: Icons.schedule_rounded,
      category: 'ACADÉMICO',
    ),
    NavItem(
      section: NavSection.sesiones,
      title: 'Sesiones de Clase',
      icon: Icons.event_available_rounded,
      category: 'ACADÉMICO',
    ),
    NavItem(
      section: NavSection.excepciones,

      title: 'Calendario Excepciones',
      icon: Icons.event_busy_outlined,
      category: 'ACADÉMICO',
    ),
    NavItem(
      section: NavSection.dispositivos,
      title: 'Dispositivos Confiables',
      icon: Icons.phonelink_lock_rounded,
      category: 'SEGURIDAD Y CONTROL',
    ),
    NavItem(
      section: NavSection.parametros,
      title: 'Parametrización',
      icon: Icons.tune_rounded,
      category: 'CONFIGURACIÓN',
    ),
    NavItem(
      section: NavSection.marcajes,
      title: 'Gestión de Marcajes',
      icon: Icons.how_to_reg_rounded,
      category: 'CONTROL Y ASISTENCIA',
    ),
    NavItem(
      section: NavSection.justificaciones,
      title: 'Justificaciones',
      icon: Icons.fact_check_outlined,
      category: 'CONTROL Y ASISTENCIA',
      permiso: 'justificacion:leer',
    ),
    NavItem(
      section: NavSection.reportes,
      title: 'Reportes de Cumplimiento',
      icon: Icons.insights_rounded,
      category: 'REPORTES',
      permiso: 'reporte:leer',
    ),
    NavItem(
      section: NavSection.tablero,
      title: 'Tablero en Vivo',
      icon: Icons.monitor_heart_outlined,
      category: 'REPORTES',
      permiso: 'reporte:leer',
    ),
    NavItem(
      section: NavSection.ocupacion,
      title: 'Ocupación de Espacios',
      icon: Icons.meeting_room_outlined,
      category: 'REPORTES',
      permiso: 'reporte:leer',
    ),
    // El docente consulta sus grupos; el servidor aplica el ámbito (US-REP-05).
    NavItem(
      section: NavSection.asistenciaEstudiantil,
      title: 'Asistencia Estudiantil',
      icon: Icons.school_outlined,
      category: 'REPORTES',
      permiso: 'marcaje:leer',
    ),
    NavItem(
      section: NavSection.usuarios,
      title: 'Usuarios',
      icon: Icons.people_alt_outlined,
      category: 'ADMINISTRACIÓN',
      permiso: 'usuario:leer',
    ),
    NavItem(
      section: NavSection.auditoria,
      title: 'Auditoría',
      icon: Icons.manage_search_rounded,
      category: 'ADMINISTRACIÓN',
      permiso: 'auditoria:leer',
    ),
    NavItem(
      section: NavSection.privacidad,
      title: 'Aviso de privacidad',
      icon: Icons.privacy_tip_outlined,
      category: 'LEGAL',
    ),
  ];
}
