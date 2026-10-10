// supresion_dialog.dart — Evaluación previa y solicitud de supresión (US-LEG-02 AC-03)
import 'package:flutter/material.dart';

import '../../domain/models/solicitud_derecho.dart';

/// Muestra qué se elimina y qué se conserva con su fundamento; devuelve la explicación.
class SupresionDialog extends StatefulWidget {
  final List<ElementoSupresion> evaluacion;

  const SupresionDialog({super.key, required this.evaluacion});

  static Future<String?> mostrar(
          BuildContext context, List<ElementoSupresion> evaluacion) =>
      showDialog<String>(
        context: context,
        builder: (_) => SupresionDialog(evaluacion: evaluacion),
      );

  @override
  State<SupresionDialog> createState() => _SupresionDialogState();
}

class _SupresionDialogState extends State<SupresionDialog> {
  final _descripcion = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _descripcion.text.trim();
    if (texto.length < 10) {
      setState(() => _error = 'Explique la solicitud (mínimo 10 caracteres).');
      return;
    }
    Navigator.pop(context, texto);
  }

  Widget _grupo(String titulo, Iterable<ElementoSupresion> items, Color color) {
    final lista = items.toList();
    if (lista.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(titulo,
            style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      ),
      for (final e in lista)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('• ${e.descripcion}\n  ${e.fundamento}',
              style: const TextStyle(fontSize: 12)),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final ev = widget.evaluacion;
    return AlertDialog(
      title: const Text('Solicitar supresión'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _grupo('Se eliminarán', ev.where((e) => e.eliminable),
                Colors.green.shade700),
            _grupo('Se conservarán por obligación legal',
                ev.where((e) => !e.eliminable), Colors.orange.shade800),
            TextField(
              controller: _descripcion,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Motivo'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _enviar, child: const Text('Radicar')),
      ],
    );
  }
}
