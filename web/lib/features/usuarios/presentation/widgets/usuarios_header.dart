import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Encabezado de la pantalla con las acciones "Nuevo usuario" e "Importar CSV".
class UsuariosHeader extends StatelessWidget {
  final VoidCallback onNuevo;
  final VoidCallback onImportar;

  const UsuariosHeader({
    super.key,
    required this.onNuevo,
    required this.onImportar,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: AppColors.primaryAccent,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Usuarios', style: AppTextStyles.h1),
                Text(
                  'Cuentas, roles y ámbitos de actuación (US-ROL-01..05)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: onImportar,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Importar CSV'),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: onNuevo,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Nuevo usuario'),
            ),
          ],
        ),
      ],
    );
  }
}
