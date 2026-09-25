import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Panel inferior con accesos a módulos operativos complementarios de SIAA.
class ModulosSecundariosPanel extends StatelessWidget {
  final bool isDark;

  const ModulosSecundariosPanel({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFeatureTile(
          context,
          icon: Icons.qr_code_scanner_rounded,
          title: 'Marcaje de Asistencia',
          subtitle: 'Validación por geocerca y token de sesión',
          enabled: true,
          onTap: () => Navigator.pushNamed(context, '/shell/inicio'),
        ),
        const SizedBox(height: 10),
        _buildFeatureTile(
          context,
          icon: Icons.history_rounded,
          title: 'Historial de Asistencia',
          subtitle: 'Registros y justificaciones de clase',
          enabled: true,
          onTap: () => Navigator.pushNamed(context, '/shell/historial'),
        ),
      ],
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SIAAColors.neutral200),
        ),
        child: Row(
        children: [
          Icon(
            icon,
            color: enabled ? SIAAColors.primary500 : SIAAColors.neutral400,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: enabled ? null : SIAAColors.neutral500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: SIAAColors.neutral400),
                ),
              ],
            ),
          ),
          if (!enabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: SIAAColors.neutral100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Pronto',
                style: TextStyle(fontSize: 10, color: SIAAColors.neutral600),
              ),
            ),
        ],
      ),
    ),
  );
}
}
