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
}

class NavItem {
  final NavSection section;
  final String title;
  final IconData icon;
  final String category;

  const NavItem({
    required this.section,
    required this.title,
    required this.icon,
    required this.category,
  });

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
  ];
}

