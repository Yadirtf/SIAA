import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/busqueda_texto.dart';
import '../../data/models/estudiante_grupo_model.dart';

/// Lista filtrable de estudiantes del grupo y de identificadores pendientes,
/// cada uno con botón para retirarlo.
class ListaEstudiantesGrupo extends StatelessWidget {
  final List<EstudianteGrupo> estudiantes;
  final List<String> pendientes;
  final String filtro;
  final ValueChanged<String> onQuitarEstudiante;
  final ValueChanged<String> onQuitarPendiente;

  const ListaEstudiantesGrupo({
    super.key,
    required this.estudiantes,
    required this.pendientes,
    required this.filtro,
    required this.onQuitarEstudiante,
    required this.onQuitarPendiente,
  });

  Widget _quitar(String tooltip, VoidCallback onPressed) => IconButton(
    icon: const Icon(Icons.person_remove_outlined, color: AppColors.accentRose),
    tooltip: tooltip,
    onPressed: onPressed,
  );

  @override
  Widget build(BuildContext context) {
    final visibles = filtrarPorTexto(
      estudiantes,
      (e) => '${e.nombre} ${e.correo} ${e.documento ?? ''}',
      filtro,
      limite: estudiantes.length,
    );
    final pend = filtrarPorTexto(
      pendientes,
      (p) => p,
      filtro,
      limite: pendientes.length,
    );
    if (visibles.isEmpty && pend.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            estudiantes.isEmpty && pendientes.isEmpty
                ? 'El grupo no tiene estudiantes.'
                : 'Ningún estudiante coincide con la búsqueda.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      children: [
        for (final p in pend)
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.schedule_outlined,
              color: AppColors.accentAmber,
            ),
            title: Text(p),
            subtitle: const Text('Pendiente por guardar'),
            trailing: _quitar('Quitar $p', () => onQuitarPendiente(p)),
          ),
        for (final e in visibles)
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.person_outline,
              color: AppColors.primaryAccent,
            ),
            title: Text(e.nombre),
            subtitle: Text(
              [
                e.correo,
                if (e.documento != null) 'Doc. ${e.documento}',
              ].join(' · '),
            ),
            trailing: _quitar(
              'Quitar ${e.nombre}',
              () => onQuitarEstudiante(e.id),
            ),
          ),
      ],
    );
  }
}
