import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/geo_bloc.dart';
import '../bloc/geo_event.dart';
import '../bloc/geo_state.dart';

class SedesScreen extends StatelessWidget {
  const SedesScreen({super.key});

  void _showCreateDialog(BuildContext context) {
    final codigoCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    final direccionCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Nueva Sede Universitaria', style: AppTextStyles.h3),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: codigoCtrl,
                decoration: const InputDecoration(labelText: 'Código (ej: SEDE-MED)'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre de la Sede'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: direccionCtrl,
                decoration: const InputDecoration(labelText: 'Dirección o Campus'),
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
                context.read<GeoBloc>().add(
                      CreateSedeEvent(
                        codigo: codigoCtrl.text.trim(),
                        nombre: nombreCtrl.text.trim(),
                        direccion: direccionCtrl.text.trim(),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sedes y Campus', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text('Administración de recintos físicos principales', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nueva Sede'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BlocBuilder<GeoBloc, GeoState>(
              buildWhen: (prev, curr) => curr is GeoLoaded || curr is GeoLoading || curr is GeoError,
              builder: (context, state) {
                if (state is GeoLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is GeoError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.accentRose, size: 40),
                        const SizedBox(height: 12),
                        Text(state.message, style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.read<GeoBloc>().add(const LoadGeoDataEvent()),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is GeoLoaded) {
                  if (state.sedes.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return ListView.separated(
                    itemCount: state.sedes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final sede = state.sedes[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryAccent.withOpacity(0.12),
                            child: const Icon(Icons.domain_rounded, color: AppColors.primaryAccent),
                          ),
                          title: Text('${sede.nombre} (${sede.codigo})', style: AppTextStyles.h3),
                          subtitle: Text(sede.direccion ?? 'Sin dirección especificada', style: AppTextStyles.bodyMedium),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: sede.activo ? AppColors.statusSuccessBg : AppColors.statusWarningBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              sede.activo ? 'ACTIVO' : 'INACTIVO',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: sede.activo ? AppColors.statusSuccessText : AppColors.statusWarningText,
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.domain_disabled_rounded, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No hay sedes registradas', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text('Crea la primera sede para comenzar a registrar bloques y espacios.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Registrar Sede'),
          ),
        ],
      ),
    );
  }
}
