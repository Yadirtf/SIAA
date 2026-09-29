import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/usuario_model.dart';
import 'usuario_acciones_menu.dart';
import 'usuario_estado_badge.dart';

/// Tabla de usuarios: nombre, correo, documento, roles, ámbitos y estado.
class UsuariosTable extends StatelessWidget {
  final List<UsuarioModel> usuarios;
  final bool procesando;
  final void Function(UsuarioModel usuario, UsuarioAccion accion) onAccion;

  const UsuariosTable({
    super.key,
    required this.usuarios,
    required this.onAccion,
    this.procesando = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
          headingTextStyle: AppTextStyles.label,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 72,
          columns: const [
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('Correo')),
            DataColumn(label: Text('Documento')),
            DataColumn(label: Text('Roles')),
            DataColumn(label: Text('Ámbitos'), numeric: true),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: usuarios.map(_fila).toList(),
        ),
      ),
    );
  }

  DataRow _fila(UsuarioModel u) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                u.nombreCompleto,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (u.totpActivado) ...[
                const SizedBox(width: 6),
                const Tooltip(
                  message: 'Doble factor activado',
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 16,
                    color: AppColors.accentEmerald,
                  ),
                ),
              ],
            ],
          ),
        ),
        DataCell(Text(u.correo)),
        DataCell(Text(u.documento ?? '—')),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: u.roles.map(_rolChip).toList(),
            ),
          ),
        ),
        DataCell(
          Tooltip(
            message: u.ambitos.isEmpty
                ? 'Sin restricción de ámbito'
                : u.ambitos.map((a) => '${a.tipo}: ${a.id}').join('\n'),
            child: Text('${u.ambitos.length}'),
          ),
        ),
        DataCell(UsuarioEstadoBadge(usuario: u)),
        DataCell(
          UsuarioAccionesMenu(
            usuario: u,
            habilitado: !procesando,
            onAccion: (accion) => onAccion(u, accion),
          ),
        ),
      ],
    );
  }

  Widget _rolChip(String rol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.statusInfoBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        rol,
        style: const TextStyle(
          color: AppColors.statusInfoText,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
