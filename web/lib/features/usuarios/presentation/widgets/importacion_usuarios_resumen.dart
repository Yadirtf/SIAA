import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/importacion_usuarios_model.dart';

/// Resumen y detalle por fila de una importación de usuarios.
class ImportacionUsuariosResumen extends StatelessWidget {
  final ImportacionUsuariosModel resultado;

  const ImportacionUsuariosResumen({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r.confirmado ? 'Resultado de la importación' : 'Validación previa',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(
              'Total filas: ${r.total}',
              AppColors.statusInfoBg,
              AppColors.statusInfoText,
            ),
            _chip(
              'Válidas: ${r.validas}',
              AppColors.statusSuccessBg,
              AppColors.statusSuccessText,
            ),
            _chip(
              'Con error: ${r.conError}',
              AppColors.statusWarningBg,
              AppColors.statusWarningText,
            ),
            if (r.confirmado)
              _chip(
                'Creados: ${r.creados}',
                AppColors.statusSuccessBg,
                AppColors.statusSuccessText,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: ListView(
            shrinkWrap: true,
            children: r.filas.map(_fila).toList(),
          ),
        ),
      ],
    );
  }

  Widget _fila(FilaImportacionUsuarioModel f) {
    final ok = f.valida && f.error == null;
    final (icono, color) = f.creado
        ? (Icons.check_circle_rounded, AppColors.statusSuccessText)
        : ok
        ? (Icons.check_circle_outline_rounded, AppColors.statusInfoText)
        : (Icons.error_outline_rounded, AppColors.accentAmber);
    final nombre = f.nombre.isEmpty ? '' : ' · ${f.nombre}';
    return ListTile(
      dense: true,
      leading: Icon(icono, color: color, size: 18),
      title: Text('Fila ${f.fila}: ${f.correo}$nombre'),
      subtitle: f.error != null
          ? Text(
              f.error!,
              style: const TextStyle(color: AppColors.statusDangerText),
            )
          : Text(f.creado ? 'Creado' : 'Lista para crear'),
    );
  }

  Widget _chip(String texto, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
