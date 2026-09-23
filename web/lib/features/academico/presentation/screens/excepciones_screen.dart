import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';
import '../bloc/academico_state.dart';

class ExcepcionesScreen extends StatelessWidget {
  const ExcepcionesScreen({super.key});

  void _showCreateDialog(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final inicioCtrl = TextEditingController(text: '2026-03-23');
    final finCtrl = TextEditingController(text: '2026-03-23');
    String selectedTipo = 'FESTIVO';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setMState) => AlertDialog(
          title: Text('Nueva Excepción de Calendario', style: AppTextStyles.h3),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre / Motivo (ej: Día Festivo)'),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTipo,
                  decoration: const InputDecoration(labelText: 'Tipo de Excepción'),
                  items: const [
                    DropdownMenuItem(value: 'FESTIVO', child: Text('Festivo Oficial')),
                    DropdownMenuItem(value: 'RECESO', child: Text('Semana de Receso')),
                    DropdownMenuItem(value: 'JORNADA_INSTITUCIONAL', child: Text('Jornada Institucional')),
                    DropdownMenuItem(value: 'PARO', child: Text('Suspensión / Paro')),
                  ],
                  onChanged: (val) {
                    if (val != null) setMState(() => selectedTipo = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: inicioCtrl,
                        decoration: const InputDecoration(labelText: 'Fecha Inicio'),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: finCtrl,
                        decoration: const InputDecoration(labelText: 'Fecha Fin'),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  context.read<AcademicoBloc>().add(
                        CreateExcepcionEvent(
                          nombre: nombreCtrl.text.trim(),
                          tipo: selectedTipo,
                          ambito: 'GLOBAL',
                          fechaInicio: inicioCtrl.text.trim(),
                          fechaFin: finCtrl.text.trim(),
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
                    Text('Calendario de Excepciones', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text('Días festivos, recesos académicos y suspensiones de jornada', style: AppTextStyles.bodyMedium),
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
              buildWhen: (prev, curr) => curr is AcademicoLoaded || curr is AcademicoLoading || curr is AcademicoError,
              builder: (context, state) {
                if (state is AcademicoLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AcademicoError) {
                  return Center(child: Text(state.message, style: AppTextStyles.bodyMedium));
                }
                if (state is AcademicoLoaded) {
                  if (state.excepciones.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available_rounded, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text('No hay excepciones registradas en el calendario', style: AppTextStyles.h3),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.accentRose.withOpacity(0.12),
                            child: const Icon(Icons.event_busy_rounded, color: AppColors.accentRose),
                          ),
                          title: Text('${e.nombre} (${e.tipo})', style: AppTextStyles.h3),
                          subtitle: Text('Del ${e.fechaInicio} al ${e.fechaFin} • Ámbito: ${e.ambito}', style: AppTextStyles.bodyMedium),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.accentRose),
                            onPressed: () => context.read<AcademicoBloc>().add(DeleteExcepcionEvent(e.id)),
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
