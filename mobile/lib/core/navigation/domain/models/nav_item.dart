// nav_item.dart - Entidad de item de navegacion (SIAA Movil)
// RF-ROL-001, RF-ROL-003
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Representa un destino de navegacion en la aplicacion movil SIAA.
/// [permiso] es el permiso en formato 'recurso:accion' requerido por backend.
/// Si [permiso] es null, el destino es de acceso publico para cualquier rol.
class NavItem extends Equatable {
  final String label;
  final IconData icon;
  final IconData iconSelected;
  final String route;
  final String? permiso;

  const NavItem({
    required this.label,
    required this.icon,
    required this.route,
    IconData? iconSelected,
    this.permiso,
  }) : iconSelected = iconSelected ?? icon;

  @override
  List<Object?> get props => [label, icon, iconSelected, route, permiso];
}
