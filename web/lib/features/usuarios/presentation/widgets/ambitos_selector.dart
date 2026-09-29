import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/ambito_model.dart';
import '../bloc/catalogo_usuarios_cubit.dart';

/// Selección de ámbitos (sedes, facultades, bloques) de un usuario.
class AmbitosSelector extends StatelessWidget {
  final Set<AmbitoModel> seleccionados;
  final ValueChanged<Set<AmbitoModel>> onChanged;

  const AmbitosSelector({
    super.key,
    required this.seleccionados,
    required this.onChanged,
  });

  void _alternar(AmbitoModel ambito, bool activo) {
    final nuevos = {...seleccionados};
    activo ? nuevos.add(ambito) : nuevos.remove(ambito);
    onChanged(nuevos);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogoUsuariosCubit, CatalogoUsuariosState>(
      builder: (context, state) {
        if (state.cargando) return const LinearProgressIndicator();
        final c = state.catalogo;
        final grupos = <String, List<MapEntry<String, String>>>{
          TipoAmbito.sede: c.sedes
              .map((s) => MapEntry(s.id, s.nombre))
              .toList(),
          TipoAmbito.facultad: c.facultades
              .map((f) => MapEntry(f.id, f.nombre))
              .toList(),
          TipoAmbito.bloque: c.bloques
              .map((b) => MapEntry(b.id, '${b.codigo} · ${b.nombre}'))
              .toList(),
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sin ámbitos, el usuario actúa sobre toda la institución '
              'según sus roles.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            for (final tipo in TipoAmbito.todos)
              _grupo(tipo, grupos[tipo]!, c.nombreAmbito),
            if (state.error != null || c.errores.isNotEmpty)
              Text(
                state.error ?? c.errores.join('\n'),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.statusDangerText,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _grupo(
    String tipo,
    List<MapEntry<String, String>> opciones,
    String Function(String, String) nombre,
  ) {
    // Incluye ámbitos ya asignados que no estén en el catálogo cargado.
    final ids = opciones.map((o) => o.key).toSet();
    final extra = seleccionados
        .where((a) => a.tipo == tipo && !ids.contains(a.id))
        .map((a) => MapEntry(a.id, nombre(tipo, a.id)));
    final todas = [...opciones, ...extra];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(TipoAmbito.plural(tipo), style: AppTextStyles.label),
          const SizedBox(height: 6),
          if (todas.isEmpty)
            Text(
              'Sin registros',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: todas.map((o) {
              final ambito = AmbitoModel(tipo: tipo, id: o.key);
              return FilterChip(
                label: Text(o.value),
                selected: seleccionados.contains(ambito),
                selectedColor: AppColors.statusSuccessBg,
                onSelected: (v) => _alternar(ambito, v),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
