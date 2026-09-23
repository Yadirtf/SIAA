import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';
import '../bloc/academico_state.dart';

class PeriodosScreen extends StatelessWidget {
  const PeriodosScreen({super.key});

  void _showCreateDialog(BuildContext context) {
    final codigoCtrl = TextEditingController(text: '2026-1');
    final nombreCtrl = TextEditingController(text: 'Primer Semestre 2026');
    final inicioCtrl = TextEditingController(text: '2026-02-01');
    final finCtrl = TextEditingController(text: '2026-06-30');
    String selectedEstado = 'PLANEACION';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text('Nuevo Periodo Académico', style: AppTextStyles.h3),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codigoCtrl,
                  decoration: const InputDecoration(labelText: 'Código (ej: 2026-1)'),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: inicioCtrl,
                        decoration: const InputDecoration(labelText: 'Fecha Inicio (YYYY-MM-DD)'),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: finCtrl,
                        decoration: const InputDecoration(labelText: 'Fecha Fin (YYYY-MM-DD)'),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedEstado,
                  decoration: const InputDecoration(labelText: 'Estado Inicial'),
                  items: const [
                    DropdownMenuItem(value: 'PLANEACION', child: Text('PLANEACIÓN')),
                    DropdownMenuItem(value: 'ACTIVO', child: Text('ACTIVO')),
                    DropdownMenuItem(value: 'CERRADO', child: Text('CERRADO')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedEstado = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  context.read<AcademicoBloc>().add(
                        CreatePeriodoEvent(
                          codigo: codigoCtrl.text.trim(),
                          nombre: nombreCtrl.text.trim(),
                          fechaInicio: inicioCtrl.text.trim(),
                          fechaFin: finCtrl.text.trim(),
                          estado: selectedEstado,
                        ),
                      );
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
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
                    Text('Periodos Académicos', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text('Ciclos lectivos, planeación operativa y rangos de fecha', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo Periodo'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BlocBuilder<AcademicoBloc, AcademicoState>(
              buildWhen: (prev, curr) => curr is AcademicoLoaded || curr is AcademicoLoading || curr is AcademicoError,
              builder: (context, state) {
                if (state is AcademicoLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AcademicoError) {
                  return Center(child: Text(state.message, style: AppTextStyles.bodyMedium));
                }
                if (state is AcademicoLoaded) {
                  if (state.periodos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text('No hay periodos académicos registrados', style: AppTextStyles.h3),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showCreateDialog(context),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight.withOpacity(0.12),
                            child: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryLight),
                          ),
                          title: Text('${p.nombre} (${p.codigo})', style: AppTextStyles.h3),
                          subtitle: Text('Del ${p.fechaInicio} al ${p.fechaFin}', style: AppTextStyles.bodyMedium),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.estado == 'ACTIVO' ? AppColors.statusSuccessBg : AppColors.statusInfoBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              p.estado,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: p.estado == 'ACTIVO' ? AppColors.statusSuccessText : AppColors.statusInfoText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
