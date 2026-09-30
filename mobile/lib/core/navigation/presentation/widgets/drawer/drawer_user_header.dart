import 'package:flutter/material.dart';
import 'package:siaa_mobile/core/theme/app_theme.dart';

class DrawerUserHeader extends StatelessWidget {
  final String nombre;

  const DrawerUserHeader({super.key, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: SIAASpacing.lg,
        vertical: SIAASpacing.md,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: SIAAColors.primary100,
            child: Text(
              inicial,
              style: const TextStyle(
                color: SIAAColors.primary700,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: SIAASpacing.md),
          Expanded(
            child: Text(
              nombre,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isDark ? SIAAColors.neutral100 : SIAAColors.neutral800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
