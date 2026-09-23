import 'package:flutter/material.dart';

/// Diálogo modal para registrar un nuevo Bloque o Edificio dentro de una Sede (US-GEO-01).
class CrearBloqueDialog extends StatefulWidget {
  final String sedeNombre;
  final Future<void> Function({
    required String codigo,
    required String nombre,
    required List<int> pisos,
  }) onGuardar;

  const CrearBloqueDialog({
    super.key,
    required this.sedeNombre,
    required this.onGuardar,
  });

  @override
  State<CrearBloqueDialog> createState() => _CrearBloqueDialogState();
}

class _CrearBloqueDialogState extends State<CrearBloqueDialog> {
  final TextEditingController _codCtrl = TextEditingController(text: 'BLQ-A');
  final TextEditingController _nomCtrl = TextEditingController(text: 'Bloque A — Ciencias e Ingenierías');
  bool _enviando = false;

  @override
  void dispose() {
    _codCtrl.dispose();
    _nomCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cod = _codCtrl.text.trim();
    final nom = _nomCtrl.text.trim();
    if (cod.isEmpty || nom.isEmpty) return;

    setState(() => _enviando = true);
    Navigator.of(context).pop();
    await widget.onGuardar(
      codigo: cod,
      nombre: nom,
      pisos: const [1, 2, 3, 4],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nuevo Bloque en ${widget.sedeNombre}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _codCtrl,
            decoration: const InputDecoration(labelText: 'Código de Bloque (ej: BLQ-A)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nomCtrl,
            decoration: const InputDecoration(labelText: 'Nombre del Bloque'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _submit,
          child: const Text('Guardar Bloque'),
        ),
      ],
    );
  }
}
