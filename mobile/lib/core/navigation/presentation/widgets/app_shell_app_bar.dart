import 'package:flutter/material.dart';
import 'package:siaa_mobile/core/theme/app_theme.dart';
import '../../config/rol_slug.dart';
import '../bloc/nav_state.dart';

class AppShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  final NavState navState;

  /// Nombre de la sección visible; sin él se muestra "SIAA".
  final String? titulo;

  const AppShellAppBar({
    super.key,
    required this.navState,
    this.titulo,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelRol = etiquetaRol(navState.rolActivo);

    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: SIAAColors.primary500,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo ?? 'SIAA',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              if (navState.rolActivo.isNotEmpty)
                Text(
                  labelRol,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
