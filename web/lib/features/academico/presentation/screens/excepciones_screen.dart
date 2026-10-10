import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';
import '../bloc/academico_state.dart';
import '../cubit/excepciones_cubit.dart';
import '../dialogs/excepcion_dialog.dart';

/// Calendario de excepciones (US-ACA-04): crear con ámbito, eliminar y, si la
/// eliminación libera sesiones, ofrecer regenerarlas sin hacerlo solo (AC-04).
class ExcepcionesScreen extends StatelessWidget {
  final ExcepcionesCubit? cubit;

  const ExcepcionesScreen({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExcepcionesCubit>(
      create: (_) => cubit ?? ExcepcionesCubit(),
      child: BlocListener<ExcepcionesCubit, ExcepcionesState>(
        listener: _alCambiar,
        child: const _ExcepcionesVista(),
      ),
    );
  }

  void _alCambiar(BuildContext context, ExcepcionesState state) {
    final texto = state.error ?? state.mensaje;
    if (texto == null) return;
    context.read<AcademicoBloc>().add(const LoadAcademicoDataEvent());
    final liberadas = state.liberadas;
    if (liberadas == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(texto)));
      return;
    }
    final cubit = context.read<ExcepcionesCubit>();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fechas liberadas'),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              cubit.regenerar(liberadas);
            },
            child: const Text('Regenerar sesiones'),
          ),
        ],
      ),
    );
  }
}

class _ExcepcionesVista extends StatelessWidget {
  const _ExcepcionesVista();

  Future<void> _showCreateDialog(BuildContext context) async {
    final cubit = context.read<ExcepcionesCubit>();
    final nueva = await ExcepcionDialog.mostrar(context);
    if (nueva == null) return;
    await cubit.crear(
      nombre: nueva.nombre,
      tipo: nueva.tipo,
      ambito: nueva.ambito,
      ambitoId: nueva.ambitoId,
      fechaInicio: nueva.fechaInicio,
      fechaFin: nueva.fechaFin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calendario de Excepciones', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text(
                      'Días festivos, recesos académicos y suspensiones de jornada',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nueva Excepción'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BlocBuilder<AcademicoBloc, AcademicoState>(
              buildWhen: (prev, curr) =>
                  curr is AcademicoLoaded ||
                  curr is AcademicoLoading ||
                  curr is AcademicoError,
              builder: (context, state) {
                if (state is AcademicoLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AcademicoError) {
                  return Center(
                    child: Text(state.message, style: AppTextStyles.bodyMedium),
                  );
                }
                if (state is AcademicoLoaded) {
                  if (state.excepciones.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 48,
                            color: AppColors.textMuted.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay excepciones registradas en el calendario',
                            style: AppTextStyles.h3,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showCreateDialog(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Registrar Festivo o Receso'),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: state.excepciones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final e = state.excepciones[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.accentRose.withOpacity(
                              0.12,
                            ),
                            child: const Icon(
                              Icons.event_busy_rounded,
                              color: AppColors.accentRose,
                            ),
                          ),
                          title: Text(
                            '${e.nombre} (${e.tipo})',
                            style: AppTextStyles.h3,
                          ),
                          subtitle: Text(
                            'Del ${e.fechaInicio} al ${e.fechaFin} • Ámbito: ${e.ambito}',
                            style: AppTextStyles.bodyMedium,
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.accentRose,
                            ),
                            tooltip: 'Eliminar',
                            onPressed: () =>
                                context.read<ExcepcionesCubit>().eliminar(e.id),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
