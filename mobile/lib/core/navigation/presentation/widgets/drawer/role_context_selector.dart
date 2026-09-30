import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaa_mobile/core/theme/app_theme.dart';
import 'package:siaa_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import '../../../config/rol_slug.dart';
import '../../bloc/nav_state.dart';

class RoleContextSelector extends StatelessWidget {
  final NavState navState;

  const RoleContextSelector({
    super.key,
    required this.navState,
  });

  @override
  Widget build(BuildContext context) {
    if (navState.rolesDisponibles.length <= 1) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SIAASpacing.lg,
        vertical: SIAASpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTEXTO ACTIVO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isDark ? SIAAColors.neutral500 : SIAAColors.neutral400,
            ),
          ),
          const SizedBox(height: SIAASpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SIAASpacing.md,
              vertical: SIAASpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isDark ? SIAAColors.neutral800 : SIAAColors.neutral100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? SIAAColors.neutral700 : SIAAColors.neutral200,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                // Los valores son slugs ("admin"); rolActivo también lo es.
                value: rolSlugDe(navState.rolActivo),
                isExpanded: true,
                isDense: true,
                icon: const Icon(Icons.unfold_more_rounded, size: 18),
                items: {
                  for (final rol in navState.rolesDisponibles)
                    rolSlugDe(rol): rol,
                }.entries.map((e) {
                  return DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(
                      etiquetaRol(e.value),
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (nuevoSlug) {
                  if (nuevoSlug != null && nuevoSlug != navState.rolActivo) {
                    Navigator.of(context).pop();
                    // El backend emite un token con los permisos del nuevo rol
                    // (POST /auth/contexto); al llegar, el shell reconstruye la navegación.
                    context.read<AuthBloc>().add(AuthContextoSolicitado(
                          rolBackendDe(nuevoSlug,
                              disponibles: navState.rolesDisponibles),
                        ));
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: SIAASpacing.sm),
        ],
      ),
    );
  }
}
