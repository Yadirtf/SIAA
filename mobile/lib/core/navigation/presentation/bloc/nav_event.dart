// nav_event.dart - Eventos del BLoC de navegacion (SIAA Movil)
// RF-ROL-001, RF-ROL-004
import 'package:equatable/equatable.dart';

abstract class NavEvent extends Equatable {
  const NavEvent();

  @override
  List<Object?> get props => [];
}

/// Inicializa la navegacion con los roles y permisos resueltos por el backend (RF-ROL-001).
class NavInicializado extends NavEvent {
  final List<String> rolesUsuario;
  final List<String> permisosUsuario;

  const NavInicializado({
    required this.rolesUsuario,
    required this.permisosUsuario,
  });

  @override
  List<Object?> get props => [rolesUsuario, permisosUsuario];
}

/// Cambia el contexto activo a otro rol del usuario sin cerrar sesion (RF-ROL-004).
class NavContextoCambiado extends NavEvent {
  final String nuevoRolSlug;

  const NavContextoCambiado(this.nuevoRolSlug);

  @override
  List<Object?> get props => [nuevoRolSlug];
}

/// Cambia la pestana activa en la barra de navegacion inferior.
class NavTabCambiado extends NavEvent {
  final int nuevoIndex;

  const NavTabCambiado(this.nuevoIndex);

  @override
  List<Object?> get props => [nuevoIndex];
}

/// Selecciona un destino desde el Drawer (modulo extra o destino comun).
class NavDrawerItemSelected extends NavEvent {
  final String route;

  const NavDrawerItemSelected(this.route);

  @override
  List<Object?> get props => [route];
}
