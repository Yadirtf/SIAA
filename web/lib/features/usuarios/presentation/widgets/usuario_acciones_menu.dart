import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/usuario_model.dart';

enum UsuarioAccion {
  editar,
  roles,
  ambitos,
  activar,
  desactivar,
  desbloquear,
  cerrarSesiones,
}

/// Menú de acciones por fila; solo ofrece las que aplican al estado actual.
class UsuarioAccionesMenu extends StatelessWidget {
  final UsuarioModel usuario;
  final bool habilitado;
  final void Function(UsuarioAccion accion) onAccion;

  const UsuarioAccionesMenu({
    super.key,
    required this.usuario,
    required this.onAccion,
    this.habilitado = true,
  });

  PopupMenuItem<UsuarioAccion> _item(
    UsuarioAccion accion,
    IconData icono,
    String texto, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: accion,
      child: Row(
        children: [
          Icon(icono, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(texto, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<UsuarioAccion>(
      tooltip: 'Acciones',
      enabled: habilitado,
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: onAccion,
      itemBuilder: (_) => [
        _item(UsuarioAccion.editar, Icons.edit_outlined, 'Editar datos'),
        _item(
          UsuarioAccion.roles,
          Icons.admin_panel_settings_outlined,
          'Roles',
        ),
        _item(UsuarioAccion.ambitos, Icons.location_city_outlined, 'Ámbitos'),
        const PopupMenuDivider(),
        if (usuario.bloqueado)
          _item(
            UsuarioAccion.desbloquear,
            Icons.lock_open_rounded,
            'Desbloquear',
          ),
        _item(
          UsuarioAccion.cerrarSesiones,
          Icons.logout_rounded,
          'Cerrar sesiones activas',
        ),
        if (usuario.activo)
          _item(
            UsuarioAccion.desactivar,
            Icons.person_off_outlined,
            'Desactivar',
            color: AppColors.accentRose,
          )
        else
          _item(
            UsuarioAccion.activar,
            Icons.person_outline_rounded,
            'Activar',
            color: AppColors.statusSuccessText,
          ),
      ],
    );
  }
}
