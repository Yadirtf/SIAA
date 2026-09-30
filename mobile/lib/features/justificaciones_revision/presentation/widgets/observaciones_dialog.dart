// observaciones_dialog.dart — Captura de observaciones al aprobar o rechazar (RF-JUS-002)
import 'package:flutter/material.dart';

class ObservacionesDialog extends StatefulWidget {
  final String titulo;
  final String accion;

  /// Mínimo de caracteres (0 = opcional).
  final int minimo;

  const ObservacionesDialog({
    super.key,
    required this.titulo,
    required this.accion,
    this.minimo = 0,
  });

  /// Devuelve el texto escrito o null si se cancela.
  static Future<String?> mostrar(BuildContext context,
      {required String titulo, required String accion, int minimo = 0}) {
    return showDialog<String>(
      context: context,
      builder: (_) =>
          ObservacionesDialog(titulo: titulo, accion: accion, minimo: minimo),
    );
  }

  @override
  State<ObservacionesDialog> createState() => _ObservacionesDialogState();
}

class _ObservacionesDialogState extends State<ObservacionesDialog> {
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  bool get _valido => _texto.text.trim().length >= widget.minimo;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        key: const Key('observaciones-revision'),
        controller: _texto,
        maxLines: 4,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: widget.minimo > 0
              ? 'Observaciones (obligatorias)'
              : 'Observaciones (opcional)',
          helperText: widget.minimo > 0
              ? 'Mínimo ${widget.minimo} caracteres; el docente las verá.'
              : 'El docente las verá junto con la decisión.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _valido
              ? () => Navigator.of(context).pop(_texto.text.trim())
              : null,
          child: Text(widget.accion),
        ),
      ],
    );
  }
}
