import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';
import '../bloc/academico_state.dart';
import '../dialogs/asignacion_dialog.dart';
import '../dialogs/importar_csv_dialog.dart';

class AsignacionesScreen extends StatelessWidget {
  const AsignacionesScreen({super.key});

  static const List<String> _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: BlocBuilder<AcademicoBloc, AcademicoState>(
        buildWhen: (prev, curr) =>
            curr is AcademicoLoaded ||
            curr is AcademicoLoading ||
            curr is AcademicoError,
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asignaciones Horarias y Aulas',
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vinculación docente-grupo-aula y franjas recurrentes (US-ACA-02, US-ACA-03, US-ACA-08)',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ImportarCsvDialog(),
                      );
                    },
                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                    label: const Text('Carga Masiva CSV'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Actualizar lista',
                    onPressed: () => context.read<AcademicoBloc>().add(
                          const LoadAcademicoDataEvent(),
                        ),
                  ),
                  const SizedBox(width: 8),
                  if (state is AcademicoLoaded)
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AsignacionDialog(
                            periodos: state.periodos,
                            grupos: state.grupos,
                            asignaturas: state.asignaturas,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nueva Asignación'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _buildContent(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AcademicoState state) {
    if (state is AcademicoLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is AcademicoError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.accentRose, size: 40),
            const SizedBox(height: 12),
            Text(state.message, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context
                  .read<AcademicoBloc>()
                  .add(const LoadAcademicoDataEvent()),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (state is AcademicoLoaded) {
      if (state.asignaciones.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 48,
                color: AppColors.textMuted.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay asignaciones horarias registradas',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 6),
              Text(
                'Utilice el botón "Nueva Asignación" o "Carga Masiva CSV" para programar horarios.',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        );
      }
      return ListView.separated(
        itemCount: state.asignaciones.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final a = state.asignaciones[index];
          final diaStr = (a.diaSemana >= 1 && a.diaSemana <= 7)
              ? _dias[a.diaSemana - 1]
              : 'Día ${a.diaSemana}';

          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryAccent.withOpacity(0.12),
                child: const Icon(
                  Icons.class_outlined,
                  color: AppColors.primaryAccent,
                ),
              ),
              title: Text(
                'Docente: ${a.docenteNombre.isNotEmpty ? a.docenteNombre : "Por asignar"}',
                style: AppTextStyles.h3,
              ),
              subtitle: Text(
                '$diaStr ${a.horaInicio} - ${a.horaFin} • Espacio: ${a.espacioNombre ?? "Sin asignar"} • Modalidad: ${a.modalidad}',
                style: AppTextStyles.bodyMedium,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: a.estado == 'CONFIRMADA'
                          ? AppColors.statusSuccessBg
                          : AppColors.statusInfoBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      a.estado,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: a.estado == 'CONFIRMADA'
                            ? AppColors.statusSuccessText
                            : AppColors.statusInfoText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.accentRose,
                    ),
                    tooltip: 'Eliminar asignación',
                    onPressed: () {
                      context.read<AcademicoBloc>().add(
                            DeleteAsignacionEvent(a.id),
                          );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
