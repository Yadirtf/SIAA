import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Editor inline del valor de un parámetro: lista para Sí/No y para
/// opciones fijas, número con su unidad para el resto. El valor editado vive
/// en [ctrl]; [error] explica por qué no se puede guardar.
class ParametroEditor extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isBool;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final Map<String, String> opciones;
  final String unidad;
  final String? error;

  const ParametroEditor({
    super.key,
    required this.ctrl,
    required this.isBool,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
    this.opciones = const {},
    this.unidad = '',
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isBool || opciones.isNotEmpty) {
      final items = isBool ? const {'true': 'Sí', 'false': 'No'} : opciones;
      return Row(
        children: [
          // Se reconstruye con el controlador para reflejar la selección.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: ctrl,
            builder: (_, value, __) => DropdownButton<String>(
              value: isBool
                  ? (value.text.toLowerCase() == 'true' ? 'true' : 'false')
                  : (items.containsKey(value.text) ? value.text : null),
              underline: const SizedBox.shrink(),
              items: [
                for (final e in items.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => ctrl.text = v ?? ctrl.text,
            ),
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
              suffixText: unidad.isEmpty ? null : unidad,
              errorText: error,
              errorMaxLines: 2,
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
