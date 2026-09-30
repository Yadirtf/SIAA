import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Editor de la lista de BSSIDs WiFi de un aula (RF-GEO-016).
/// El formato lo valida el backend; aquí sólo se evita duplicar entradas.
class BssidListEditor extends StatefulWidget {
  final List<String> bssids;
  final ValueChanged<List<String>> onChanged;
  final String? errorText;
  final bool enabled;

  const BssidListEditor({
    super.key,
    required this.bssids,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<BssidListEditor> createState() => _BssidListEditorState();
}

class _BssidListEditorState extends State<BssidListEditor> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _agregar() {
    final valor = _ctrl.text.trim();
    if (valor.isEmpty) return;
    final existe = widget.bssids.any(
      (b) => b.toLowerCase() == valor.toLowerCase(),
    );
    if (!existe) widget.onChanged([...widget.bssids, valor]);
    _ctrl.clear();
  }

  void _quitar(String bssid) {
    widget.onChanged(widget.bssids.where((b) => b != bssid).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('bssid-input'),
                controller: _ctrl,
                enabled: widget.enabled,
                decoration: const InputDecoration(
                  labelText: 'BSSID WiFi',
                  hintText: 'a4:2b:8c:11:02:9f',
                ),
                onSubmitted: (_) => _agregar(),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: widget.enabled ? _agregar : null,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.bssids.isEmpty)
          const Text(
            'Sin BSSIDs configurados.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.bssids
                .map(
                  (b) => InputChip(
                    label: Text(
                      b,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    onDeleted: widget.enabled ? () => _quitar(b) : null,
                    deleteButtonTooltipMessage: 'Quitar BSSID',
                  ),
                )
                .toList(),
          ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.statusDangerText,
            ),
          ),
        ],
      ],
    );
  }
}
