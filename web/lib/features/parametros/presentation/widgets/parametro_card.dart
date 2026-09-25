import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/parametro_model.dart';
import '../bloc/parametros_bloc.dart';
import '../bloc/parametros_event.dart';

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
            _OrigenIcon(nivel: widget.parametro.nivel),
            const SizedBox(width: 14),

            // Nombre + clave técnica
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _claveLabel(widget.parametro.clave),
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
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Badge de nivel
            _NivelBadge(nivel: widget.parametro.nivelLabel),

            const SizedBox(width: 16),

            // Valor / editor
            Expanded(
              flex: 2,
              child: _editing
                  ? _Editor(
                      ctrl: _ctrl,
                      isBool: widget.parametro.valor is bool,
                      onSave: _onSave,
                      onCancel: () => setState(() => _editing = false),
                      isSaving: widget.isSaving,
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _editing = true),
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

  String _claveLabel(String clave) {
    const labels = {
      'holgura_entrada_antes_min': 'Holgura entrada (antes)',
      'holgura_entrada_despues_min': 'Holgura entrada (después)',
      'umbral_tardanza_min': 'Umbral de tardanza',
      'holgura_salida_antes_min': 'Holgura salida (antes)',
      'holgura_salida_despues_min': 'Holgura salida (después)',
      'precision_gps_max_metros': 'Precisión GPS máxima (m)',
      'buffer_perimetral_metros': 'Buffer perimetral (m)',
      'promedio_lecturas_vertice': 'Lecturas por vértice',
      'salida_obligatoria': 'Marcaje de salida',
      'offline_permitido': 'Marcaje offline',
      'bloqueo_mock_location': 'Bloquear ubicación simulada',
      'bloqueo_dispositivo_rooteado': 'Bloquear dispositivo rooteado',
      'verificacion_complementaria': 'Verificación complementaria',
    };
    return labels[clave] ?? clave;
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────

class _OrigenIcon extends StatelessWidget {
  final String nivel;

  const _OrigenIcon({required this.nivel});

  @override
  Widget build(BuildContext context) {
    final isGlobal = nivel == 'GLOBAL';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isGlobal
            ? AppColors.surfaceMuted
            : AppColors.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isGlobal ? Icons.public_rounded : Icons.tune_rounded,
        size: 18,
        color: isGlobal ? AppColors.textMuted : AppColors.primaryAccent,
      ),
    );
  }
}

class _NivelBadge extends StatelessWidget {
  final String nivel;

  const _NivelBadge({required this.nivel});

  @override
  Widget build(BuildContext context) {
    final isGlobal = nivel == 'Global';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isGlobal
            ? AppColors.surfaceMuted
            : AppColors.primaryAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGlobal ? AppColors.border : AppColors.primaryAccent.withOpacity(0.25),
        ),
      ),
      child: Text(
        nivel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isGlobal ? AppColors.textMuted : AppColors.primaryAccent,
        ),
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isBool;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _Editor({
    required this.ctrl,
    required this.isBool,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (isBool) {
      return Row(
        children: [
          DropdownButton<String>(
            value: ctrl.text.toLowerCase() == 'true' ? 'true' : 'false',
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'true', child: Text('Sí')),
              DropdownMenuItem(value: 'false', child: Text('No')),
            ],
            onChanged: (v) {
              ctrl.text = v ?? 'false';
            },
          ),
          const SizedBox(width: 8),
          _actionButtons(onSave, onCancel, isSaving),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.primaryAccent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: AppColors.primaryAccent,
                  width: 1.5,
                ),
              ),
            ),
            onSubmitted: (_) => onSave(),
          ),
        ),
        const SizedBox(width: 6),
        _actionButtons(onSave, onCancel, isSaving),
      ],
    );
  }

  Widget _actionButtons(
    VoidCallback onSave,
    VoidCallback onCancel,
    bool isSaving,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded, size: 18),
          color: AppColors.accentEmerald,
          onPressed: isSaving ? null : onSave,
          tooltip: 'Guardar',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 18),
          color: AppColors.textMuted,
          onPressed: onCancel,
          tooltip: 'Cancelar',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }
}
