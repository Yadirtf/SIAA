import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaa_mobile/core/theme/app_theme.dart';
import '../../../config/role_navigation_matrix.dart';
import '../../bloc/nav_bloc.dart';
import '../../bloc/nav_event.dart';
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
                value: navState.rolActivo,
                isExpanded: true,
                isDense: true,
                icon: const Icon(Icons.unfold_more_rounded, size: 18),
                items: navState.rolesDisponibles.map((rol) {
                  final config = kRoleNavigationMatrix[rol.toLowerCase()];
                  return DropdownMenuItem<String>(
                    value: rol,
                    child: Text(
                      config?.rolLabel ?? rol,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (nuevoRol) {
                  if (nuevoRol != null && nuevoRol != navState.rolActivo) {
                    Navigator.of(context).pop();
                    context.read<NavBloc>().add(NavContextoCambiado(nuevoRol));
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
