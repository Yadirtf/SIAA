// permisos_sesion.dart — Consulta de permisos de la sesión para mostrar u ocultar acciones.
// No es un control de seguridad: el backend valida cada acción (RF-ROL-003).
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth_bloc.dart';

/// true si la sesión autenticada incluye [permiso]; false sin sesión o sin AuthBloc.
bool tienePermiso(BuildContext context, String permiso) {
  try {
    final estado = context.read<AuthBloc>().state;
    return estado is AuthAuthenticated && estado.permisos.contains(permiso);
  } catch (_) {
    return false;
  }
}

/// Id del usuario autenticado, o null sin sesión (o sin AuthBloc en el árbol).
String? usuarioIdSesion(BuildContext context) {
  try {
    final estado = context.read<AuthBloc>().state;
    return estado is AuthAuthenticated && estado.usuarioId.isNotEmpty
        ? estado.usuarioId
        : null;
  } catch (_) {
    return null;
  }
}
