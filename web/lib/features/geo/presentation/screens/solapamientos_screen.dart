import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/geo_bloc.dart';
import '../bloc/geo_event.dart';
import '../bloc/geo_state.dart';

class SolapamientosScreen extends StatelessWidget {
  const SolapamientosScreen({super.key});

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
                    Text(
                      'Control de Solapamientos Geoespaciales',
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Validación topológica 2D en tiempo real (US-GEO-01 / JTS)',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<GeoBloc>().add(const LoadSolapamientosEvent());
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Ejecutar Análisis'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BlocBuilder<GeoBloc, GeoState>(
              buildWhen: (prev, curr) => curr is GeoLoaded,
              builder: (context, state) {
                if (state is GeoLoaded) {
                  final items = state.solapamientos;
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.accentEmerald,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sin conflictos topológicos detectados',
                            style: AppTextStyles.h3,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Todas las geometrías de espacios son mutuamente disjuntas.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isCrit = item.tipoSeveridad == 'CRITICO';

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                (isCrit
                                        ? AppColors.accentRose
                                        : AppColors.accentAmber)
                                    .withOpacity(0.15),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: isCrit
                                  ? AppColors.accentRose
                                  : AppColors.accentAmber,
                            ),
                          ),
                          title: Text(
                            '${item.espacioANombre} vs ${item.espacioBNombre}',
                            style: AppTextStyles.h3,
                          ),
                          subtitle: Text(
                            'Área en conflicto: ${item.areaInterseccion.toStringAsFixed(2)} m²',
                            style: AppTextStyles.bodyMedium,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCrit
                                  ? AppColors.statusDangerBg
                                  : AppColors.statusWarningBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.tipoSeveridad,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isCrit
                                    ? AppColors.statusDangerText
                                    : AppColors.statusWarningText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(
                  child: Text(
                    'Presiona "Ejecutar Análisis" para evaluar la topología.',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
