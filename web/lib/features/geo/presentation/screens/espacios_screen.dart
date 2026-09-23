import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/geo_bloc.dart';
import '../bloc/geo_event.dart';
import '../bloc/geo_state.dart';

class EspaciosScreen extends StatelessWidget {
  const EspaciosScreen({super.key});

  void _showCreateDialog(BuildContext context, String currentSedeId) {
    final codigoCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    final capacidadCtrl = TextEditingController(text: '30');
    final pisoCtrl = TextEditingController(text: '1');
    String selectedTipo = 'AULA';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text('Nuevo Espacio Físico', style: AppTextStyles.h3),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codigoCtrl,
                    decoration: const InputDecoration(labelText: 'Código (ej: AUL-101)'),
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre descriptivo'),
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedTipo,
                    decoration: const InputDecoration(labelText: 'Tipo de Espacio'),
                    items: const [
                      DropdownMenuItem(value: 'AULA', child: Text('Aula Regular')),
                      DropdownMenuItem(value: 'LABORATORIO', child: Text('Laboratorio')),
                      DropdownMenuItem(value: 'AUDITORIO', child: Text('Auditorio')),
                      DropdownMenuItem(value: 'TALLER', child: Text('Taller')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedTipo = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: capacidadCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Capacidad'),
                          validator: (v) => v == null || int.tryParse(v) == null ? 'Número inválido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: pisoCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Piso'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                  context.read<GeoBloc>().add(
                        CreateEspacioEvent(
                          sedeId: currentSedeId,
                          codigo: codigoCtrl.text.trim(),
                          nombre: nombreCtrl.text.trim(),
                          capacidad: int.parse(capacidadCtrl.text.trim()),
                          tipo: selectedTipo,
                          piso: int.tryParse(pisoCtrl.text.trim()),
                        ),
                      );
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Crear Espacio'),
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
      child: BlocBuilder<GeoBloc, GeoState>(
        buildWhen: (prev, curr) => curr is GeoLoaded || curr is GeoLoading || curr is GeoError,
        builder: (context, state) {
          if (state is GeoLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GeoError) {
            return Center(child: Text(state.message, style: AppTextStyles.bodyMedium));
          }
          if (state is GeoLoaded) {
            final sedes = state.sedes;
            final selectedSedeId = state.selectedSedeId ?? (sedes.isNotEmpty ? sedes.first.id : '');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Espacios Físicos y Aulas', style: AppTextStyles.h2),
                          const SizedBox(height: 4),
                          Text('Control de inventario de aulas, capacidades y tipos', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                    if (sedes.isNotEmpty) ...[
                      DropdownButton<String>(
                        value: selectedSedeId.isNotEmpty ? selectedSedeId : null,
                        items: sedes.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nombre))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            context.read<GeoBloc>().add(LoadGeoDataEvent(sedeId: val));
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: selectedSedeId.isNotEmpty
                            ? () => _showCreateDialog(context, selectedSedeId)
                            : null,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Nuevo Espacio'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: state.espacios.isEmpty
                      ? Center(
                          child: Text(
                            sedes.isEmpty
                                ? 'Crea primero una sede antes de registrar espacios.'
                                : 'No hay espacios registrados en esta sede.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        )
                      : ListView.separated(
                          itemCount: state.espacios.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final esp = state.espacios[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.accentEmerald.withOpacity(0.12),
                                  child: const Icon(Icons.meeting_room_outlined, color: AppColors.accentEmerald),
                                ),
                                title: Text('${esp.nombre} (${esp.codigo})', style: AppTextStyles.h3),
                                subtitle: Text(
                                  'Tipo: ${esp.tipo} • Capacidad: ${esp.capacidad} est. • Piso: ${esp.piso ?? 1}',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose),
                                  tooltip: 'Eliminar espacio',
                                  onPressed: () {
                                    context.read<GeoBloc>().add(DeleteEspacioEvent(esp.id));
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
