import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/geo_bloc.dart';
import '../bloc/geo_event.dart';
import '../bloc/geo_state.dart';

class BloquesScreen extends StatelessWidget {
  const BloquesScreen({super.key});

  void _showCreateDialog(BuildContext context, String currentSedeId) {
    final codigoCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    final pisosCtrl = TextEditingController(text: '1, 2, 3');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Nuevo Bloque / Edificio', style: AppTextStyles.h3),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: codigoCtrl,
                decoration: const InputDecoration(labelText: 'Código (ej: BLQ-A)'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Bloque'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: pisosCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pisos (separados por coma)',
                  hintText: '1, 2, 3, 4',
                ),
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
                final floors = pisosCtrl.text
                    .split(',')
                    .map((s) => int.tryParse(s.trim()))
                    .whereType<int>()
                    .toList();

                context.read<GeoBloc>().add(
                      CreateBloqueEvent(
                        sedeId: currentSedeId,
                        codigo: codigoCtrl.text.trim(),
                        nombre: nombreCtrl.text.trim(),
                        pisos: floors.isNotEmpty ? floors : [1],
                      ),
                    );
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
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
                          Text('Bloques y Edificios', style: AppTextStyles.h2),
                          const SizedBox(height: 4),
                          Text('Estructuras físicas divididas por niveles y pisos', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                    if (sedes.isNotEmpty) ...[
                      DropdownButton<String>(
                        value: selectedSedeId.isNotEmpty ? selectedSedeId : null,
                        items: sedes.map((s) {
                          return DropdownMenuItem(value: s.id, child: Text(s.nombre));
                        }).toList(),
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
                        label: const Text('Nuevo Bloque'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: state.bloques.isEmpty
                      ? Center(
                          child: Text(
                            sedes.isEmpty
                                ? 'Crea primero una sede antes de registrar bloques.'
                                : 'No hay bloques en esta sede.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        )
                      : ListView.separated(
                          itemCount: state.bloques.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final bloque = state.bloques[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.accentCyan.withOpacity(0.12),
                                  child: const Icon(Icons.apartment_rounded, color: AppColors.accentCyan),
                                ),
                                title: Text('${bloque.nombre} (${bloque.codigo})', style: AppTextStyles.h3),
                                subtitle: Text('Pisos registrados: ${bloque.pisos.join(", ")}', style: AppTextStyles.bodyMedium),
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
