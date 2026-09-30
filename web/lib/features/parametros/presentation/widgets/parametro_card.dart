import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/parametro_model.dart';
import '../bloc/parametros_bloc.dart';
import '../bloc/parametros_event.dart';
import 'parametro_badges.dart';
import 'parametro_editor.dart';
import 'parametro_labels.dart';

/// Tarjeta editable para un parámetro individual.
/// Muestra el valor actual, el nivel de origen y permite editar inline.
/// US-PAR-01 AC-02: sólo muestra el input de edición; la validación es del backend.
class ParametroCard extends StatefulWidget {
  final ParametroEfectivoModel parametro;
  final String ambitoDestino; // Nivel en que se quiere guardar el override
  final String ambitoDestinoId;
  final bool isSaving;

  const ParametroCard({
    super.key,
    required this.parametro,
    required this.ambitoDestino,
    required this.ambitoDestinoId,
    required this.isSaving,
  });

  @override
  State<ParametroCard> createState() => _ParametroCardState();
}

class _ParametroCardState extends State<ParametroCard> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.parametro.valor?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Parte siempre del valor efectivo vigente, no de una edición cancelada.
  void _empezarEdicion() {
    _ctrl.text = widget.parametro.valor?.toString() ?? '';
    setState(() => _editing = true);
  }

  void _onSave() {
    if (_ctrl.text.trim().isEmpty) return;
    final raw = _ctrl.text.trim();

    // Intentar parsear al tipo correcto según el valor actual
    dynamic valor;
    final current = widget.parametro.valor;
    if (current is bool) {
      valor = raw.toLowerCase() == 'true' || raw == '1' || raw == 'sí';
    } else if (current is int) {
      valor = int.tryParse(raw) ?? raw;
    } else if (current is double) {
      valor = double.tryParse(raw) ?? raw;
    } else {
      valor = raw;
    }

    context.read<ParametrosBloc>().add(
      GuardarParametroEvent(
        request: GuardarParametroRequest(
          ambito: widget.ambitoDestino,
          ambitoId: widget.ambitoDestinoId,
          clave: widget.parametro.clave,
          valor: valor,
        ),
      ),
    );
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: widget.parametro.esGlobal
              ? AppColors.border
              : AppColors.primaryAccent.withOpacity(0.35),
          width: widget.parametro.esGlobal ? 1 : 1.5,
        ),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icono de origen
            OrigenIcon(nivel: widget.parametro.nivel),
            const SizedBox(width: 14),

            // Nombre + clave técnica
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etiquetaParametro(widget.parametro.clave),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.parametro.clave,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (ayudaParametro(widget.parametro.clave) != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      ayudaParametro(widget.parametro.clave)!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Badge de nivel
            NivelBadge(nivel: widget.parametro.nivelLabel),

            const SizedBox(width: 16),

            // Valor / editor
            Expanded(
              flex: 2,
              child: _editing
                  ? ParametroEditor(
                      ctrl: _ctrl,
                      isBool: widget.parametro.valor is bool,
                      onSave: _onSave,
                      onCancel: () => setState(() => _editing = false),
                      isSaving: widget.isSaving,
                    )
                  : GestureDetector(
                      onTap: _empezarEdicion,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.parametro.valorFormateado,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.edit_rounded,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
