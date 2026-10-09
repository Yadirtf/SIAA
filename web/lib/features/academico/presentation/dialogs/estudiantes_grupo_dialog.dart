import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/estudiantes_grupo_remote_datasource.dart';
import '../cubit/estudiantes_grupo_cubit.dart';
import '../widgets/agregar_estudiantes_box.dart';
import '../widgets/lista_estudiantes_grupo.dart';
import '../widgets/resultado_estudiantes_grupo.dart';

/// Gestión de los estudiantes de un grupo (US-MAR-13): consultar, buscar,
/// retirar, agregar por correo o documento y guardar la lista completa.
class EstudiantesGrupoDialog extends StatefulWidget {
  final String titulo;
  final int cupo;

  const EstudiantesGrupoDialog({
    super.key,
    required this.titulo,
    required this.cupo,
  });

  /// Abre el diálogo con su propio cubit; [dataSource] permite inyectar la
  /// fuente en pruebas. El cubit se cierra al cerrar el diálogo.
  static Future<void> mostrar(
    BuildContext context, {
    required String grupoId,
    required String titulo,
    required int cupo,
    EstudiantesGrupoRemoteDataSource? dataSource,
  }) => showDialog<void>(
    context: context,
    builder: (_) => BlocProvider<EstudiantesGrupoCubit>(
      create: (_) =>
          EstudiantesGrupoCubit(grupoId: grupoId, dataSource: dataSource)
            ..cargar(),
      child: EstudiantesGrupoDialog(titulo: titulo, cupo: cupo),
    ),
  );

  @override
  State<EstudiantesGrupoDialog> createState() => _EstudiantesGrupoDialogState();
}

class _EstudiantesGrupoDialogState extends State<EstudiantesGrupoDialog> {
  String _filtro = '';

  Widget _error(String mensaje) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.statusDangerBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      mensaje,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.statusDangerText,
      ),
    ),
  );

  Widget _contenido(BuildContext context, EstudiantesGrupoState s) {
    final cubit = context.read<EstudiantesGrupoCubit>();
    final ocupado = s.cargando || s.guardando;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.error != null) _error(s.error!),
        if (s.resultado != null) ...[
          ResultadoEstudiantesGrupoPanel(resultado: s.resultado!),
          const SizedBox(height: 12),
        ],
        AgregarEstudiantesBox(onAgregar: cubit.agregar, habilitado: !ocupado),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('buscar-estudiantes'),
                decoration: const InputDecoration(
                  labelText: 'Buscar por nombre, correo o documento',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _filtro = v),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${s.total} de ${widget.cupo} cupos',
              style: AppTextStyles.bodySmall.copyWith(
                color: s.total > widget.cupo
                    ? AppColors.accentRose
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Flexible(
          child: s.cargando
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : ListaEstudiantesGrupo(
                  estudiantes: s.estudiantes,
                  pendientes: s.pendientes,
                  filtro: _filtro,
                  onQuitarEstudiante: cubit.quitarEstudiante,
                  onQuitarPendiente: cubit.quitarPendiente,
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EstudiantesGrupoCubit, EstudiantesGrupoState>(
      builder: (context, s) => AlertDialog(
        title: Text('Estudiantes · ${widget.titulo}', style: AppTextStyles.h3),
        content: SizedBox(width: 640, child: _contenido(context, s)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: s.modificado && !s.guardando && !s.cargando
                ? context.read<EstudiantesGrupoCubit>().guardar
                : null,
            child: s.guardando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
