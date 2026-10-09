import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_state.dart';
import '../widgets/estado_periodo_chip.dart';
import '../widgets/generar_sesiones_boton.dart';
import '../dialogs/periodo_dialog.dart';
import '../edicion/editores_academicos.dart';

class PeriodosScreen extends StatelessWidget {
  const PeriodosScreen({super.key});

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
                    Text('Periodos Académicos', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text(
                      'Ciclos lectivos, planeación operativa y rangos de fecha',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => crearPeriodo(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo Periodo'),
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
                  if (state.periodos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 48,
                            color: AppColors.textMuted.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay periodos académicos registrados',
                            style: AppTextStyles.h3,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => crearPeriodo(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Crear Periodo'),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: state.periodos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = state.periodos[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight.withOpacity(
                              0.12,
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          title: Text(
                            '${p.nombre} (${p.codigo})',
                            style: AppTextStyles.h3,
                          ),
                          subtitle: Text(
                            'Del ${p.fechaInicio} al ${p.fechaFin}',
                            style: AppTextStyles.bodyMedium,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GenerarSesionesBoton(periodo: p),
                              const SizedBox(width: 12),
                              EstadoPeriodoChip(estado: p.estado),
                              if (p.estado != 'CERRADO')
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Editar periodo',
                                  onPressed: () => editarPeriodo(context, p),
                                ),
                            ],
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
