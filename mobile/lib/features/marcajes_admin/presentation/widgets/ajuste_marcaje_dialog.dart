// ajuste_marcaje_dialog.dart — Anular o corregir un marcaje con motivo obligatorio (US-MAR-09)
import 'package:flutter/material.dart';

import '../../../marcaje/domain/models/resultado_marcaje.dart';
import '../../domain/filtro_marcajes.dart';

class AjusteMarcajeDialog extends StatefulWidget {
  /// true = anular; false = corregir el resultado.
  final bool anular;
  final String resultadoActual;

  const AjusteMarcajeDialog({
    super.key,
    required this.anular,
    required this.resultadoActual,
  });

  static Future<AjusteMarcaje?> mostrar(
    BuildContext context, {
    required bool anular,
    required String resultadoActual,
  }) {
    return showDialog<AjusteMarcaje>(
      context: context,
      builder: (_) =>
          AjusteMarcajeDialog(anular: anular, resultadoActual: resultadoActual),
    );
  }

  @override
  State<AjusteMarcajeDialog> createState() => _AjusteMarcajeDialogState();
}

class _AjusteMarcajeDialogState extends State<AjusteMarcajeDialog> {
  final _motivo = TextEditingController();
  late String? _resultado =
      etiquetasResultado.containsKey(widget.resultadoActual)
          ? widget.resultadoActual
          : null;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  bool get _valido =>
      _motivo.text.trim().length >= AjusteMarcaje.minMotivo &&
      (widget.anular || _resultado != null);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.anular ? 'Anular marcaje' : 'Corregir resultado'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.anular)
              DropdownButtonFormField<String>(
                initialValue: _resultado,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Nuevo resultado'),
                items: [
                  for (final e in etiquetasResultado.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _resultado = v),
              ),
            TextField(
              key: const Key('motivo-ajuste'),
              controller: _motivo,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Motivo (obligatorio)',
                helperText:
                    'Mínimo ${AjusteMarcaje.minMotivo} caracteres. Queda en la bitácora.',
                counterText:
                    '${_motivo.text.trim().length}/${AjusteMarcaje.minMotivo}',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _valido
              ? () => Navigator.of(context).pop(widget.anular
                  ? AjusteMarcaje.anular(_motivo.text)
                  : AjusteMarcaje.corregir(_resultado!, _motivo.text))
              : null,
          child: Text(widget.anular ? 'Anular' : 'Guardar'),
        ),
      ],
    );
  }
}
