import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

enum DispositivoFiltro { todos, pendientes, aprobados, revocados }

class DispositivoBusquedaBar extends StatefulWidget {
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
  State<DispositivoBusquedaBar> createState() => _DispositivoBusquedaBarState();
}

class _DispositivoBusquedaBarState extends State<DispositivoBusquedaBar> {
  late final TextEditingController _usuarioCtrl;

  @override
  void initState() {
    super.initState();
    _usuarioCtrl = TextEditingController(text: widget.usuarioIdInicial);
  }

  @override
  void didUpdateWidget(covariant DispositivoBusquedaBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.usuarioIdInicial != oldWidget.usuarioIdInicial &&
        _usuarioCtrl.text != widget.usuarioIdInicial) {
      _usuarioCtrl.text = widget.usuarioIdInicial;
    }
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    super.dispose();
  }

  void _ejecutarBusqueda() {
    final query = _usuarioCtrl.text.trim();
    if (query.isNotEmpty) {
      widget.onBuscarUsuario(query);
    }
  }

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
                child: TextField(
                  controller: _usuarioCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.person_search_rounded,
                      color: AppColors.textMuted,
                    ),
                    hintText: 'Ingresa el ID del usuario o docente (ej: usr-1, 6500...)',
                    suffixIcon: _usuarioCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _usuarioCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onSubmitted: (_) => _ejecutarBusqueda(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Consultar'),
                onPressed: _ejecutarBusqueda,
              ),
              if (widget.onUsarMiUsuario != null) ...[
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
                  onPressed: widget.onUsarMiUsuario,
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'Actualizar lista',
                onPressed: widget.onRecargar,
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
    final isSelected = widget.filtroActual == filtro;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => widget.onCambiarFiltro(filtro),
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
