import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/rol_asignado_model.dart';
import '../../data/models/usuario_model.dart';
import '../bloc/usuarios_bloc.dart';
import '../bloc/usuarios_event.dart';
import '../widgets/accion_usuario_dialog.dart';
import '../widgets/roles_selector.dart';

/// Reemplaza los roles de un usuario (PUT /usuarios/:id/roles), conservando
/// la vigencia de los roles que se mantienen.
class RolesUsuarioDialog extends StatefulWidget {
  final UsuarioModel usuario;

  const RolesUsuarioDialog({super.key, required this.usuario});

  static Future<void> show(BuildContext context, UsuarioModel usuario) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RolesUsuarioDialog(usuario: usuario),
    );
  }

  @override
  State<RolesUsuarioDialog> createState() => _RolesUsuarioDialogState();
}

class _RolesUsuarioDialogState extends State<RolesUsuarioDialog> {
  late Set<String> _roles = widget.usuario.roles.toSet();
  bool _sinRoles = false;

  bool _enviar() {
    setState(() => _sinRoles = _roles.isEmpty);
    if (_sinRoles) return false;
    final previos = {for (final r in widget.usuario.rolesDetalle) r.nombre: r};
    final roles = _roles
        .map((n) => previos[n] ?? RolAsignadoModel(nombre: n))
        .toList();
    context.read<UsuariosBloc>().add(
      AsignarRolesUsuarioEvent(widget.usuario.id, roles),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AccionUsuarioDialog(
      icono: Icons.admin_panel_settings_outlined,
      titulo: 'Roles de ${widget.usuario.nombreCompleto}',
      textoConfirmar: 'Guardar roles',
      onConfirmar: _enviar,
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Los cambios de rol se auditan y aplican en el siguiente inicio '
            'de sesión del usuario.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          RolesSelector(
            seleccionados: _roles,
            onChanged: (r) => setState(() => _roles = r),
          ),
          ..._vigencias(),
          if (_sinRoles)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'El usuario debe conservar al menos un rol.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.statusDangerText,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _vigencias() {
    String f(DateTime? d) => d == null
        ? '—'
        : '${d.day.toString().padLeft(2, '0')}/'
              '${d.month.toString().padLeft(2, '0')}/${d.year}';
    final conVigencia = widget.usuario.rolesDetalle.where(
      (r) =>
          _roles.contains(r.nombre) &&
          (r.vigenciaInicio != null || r.vigenciaFin != null),
    );
    return [
      for (final r in conVigencia)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${r.nombre}: vigente del ${f(r.vigenciaInicio)} '
            'al ${f(r.vigenciaFin)}',
            style: AppTextStyles.bodySmall,
          ),
        ),
    ];
  }
}
