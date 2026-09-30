import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/catalogo_usuarios_cubit.dart';

/// Selección múltiple de roles a partir de GET /roles.
class RolesSelector extends StatelessWidget {
  final Set<String> seleccionados;
  final ValueChanged<Set<String>> onChanged;

  const RolesSelector({
    super.key,
    required this.seleccionados,
    required this.onChanged,
  });

  void _alternar(String rol, bool activo) {
    final nuevos = {...seleccionados};
    activo ? nuevos.add(rol) : nuevos.remove(rol);
    onChanged(nuevos);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogoUsuariosCubit, CatalogoUsuariosState>(
      builder: (context, state) {
        if (state.cargando) return const LinearProgressIndicator();
        final disponibles = state.catalogo.roles.map((r) => r.nombre).toList();
        // Conserva roles asignados que el catálogo no devolvió (p. ej. sin rol:leer).
        for (final r in seleccionados) {
          if (!disponibles.contains(r)) disponibles.add(r);
        }
        if (disponibles.isEmpty) {
          return Text(
            state.error ??
                (state.catalogo.errores.isNotEmpty
                    ? state.catalogo.errores.join('\n')
                    : 'No hay roles disponibles.'),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.statusDangerText,
            ),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: disponibles
              .map(
                (rol) => FilterChip(
                  label: Text(rol),
                  selected: seleccionados.contains(rol),
                  selectedColor: AppColors.statusInfoBg,
                  onSelected: (v) => _alternar(rol, v),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
