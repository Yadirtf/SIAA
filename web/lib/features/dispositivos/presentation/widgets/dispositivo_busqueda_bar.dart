import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../usuarios/presentation/widgets/selector_usuario.dart';

enum DispositivoFiltro { todos, pendientes, aprobados, revocados }

/// Barra para elegir el usuario (buscándolo por nombre, correo o documento)
/// cuyos dispositivos se consultan, más los filtros por estado.
class DispositivoBusquedaBar extends StatelessWidget {
  final String usuarioIdInicial;
  final ValueChanged<String> onBuscarUsuario;
  final VoidCallback onRecargar;
  final ValueChanged<DispositivoFiltro> onCambiarFiltro;
  final DispositivoFiltro filtroActual;
  final VoidCallback? onUsarMiUsuario;

  const DispositivoBusquedaBar({
    super.key,
    required this.usuarioIdInicial,
    required this.onBuscarUsuario,
    required this.onRecargar,
    required this.onCambiarFiltro,
    required this.filtroActual,
    this.onUsarMiUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SelectorUsuario(
                  etiqueta: 'Usuario o docente',
                  soloActivos: false,
                  denso: true,
                  idInicial: usuarioIdInicial.isEmpty ? null : usuarioIdInicial,
                  onCambio: (u) {
                    if (u != null) onBuscarUsuario(u.id);
                  },
                ),
              ),
              if (onUsarMiUsuario != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryAccent,
                    side: const BorderSide(color: AppColors.primaryAccent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.account_circle_outlined, size: 18),
                  label: const Text('Mi Usuario'),
                  onPressed: onUsarMiUsuario,
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'Actualizar lista',
                onPressed: onRecargar,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Filtrar:',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              _filterChip('Todos', DispositivoFiltro.todos),
              _filterChip(
                'Pendientes',
                DispositivoFiltro.pendientes,
                color: AppColors.accentAmber,
              ),
              _filterChip(
                'Aprobados',
                DispositivoFiltro.aprobados,
                color: AppColors.accentEmerald,
              ),
              _filterChip(
                'Revocados',
                DispositivoFiltro.revocados,
                color: AppColors.accentRose,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, DispositivoFiltro filtro, {Color? color}) {
    final isSelected = filtroActual == filtro;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onCambiarFiltro(filtro),
      selectedColor: (color ?? AppColors.primaryAccent).withOpacity(0.18),
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: isSelected
            ? (color ?? AppColors.primaryAccent)
            : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: AppColors.surfaceMuted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
