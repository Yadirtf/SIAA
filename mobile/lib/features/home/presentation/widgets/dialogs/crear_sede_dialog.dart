import 'package:flutter/material.dart';

/// Diálogo modal para registrar una nueva Sede Universitaria (US-GEO-01).
class CrearSedeDialog extends StatefulWidget {
  final Future<void> Function({
    required String codigo,
    required String nombre,
    String? direccion,
  }) onGuardar;

  const CrearSedeDialog({
    super.key,
    required this.onGuardar,
  });

  @override
  State<CrearSedeDialog> createState() => _CrearSedeDialogState();
}

class _CrearSedeDialogState extends State<CrearSedeDialog> {
  final TextEditingController _codCtrl = TextEditingController(text: 'SEDE-01');
  final TextEditingController _nomCtrl = TextEditingController(text: 'Campus Principal');
  final TextEditingController _dirCtrl = TextEditingController(text: 'Calle Universitaria #1');
  bool _enviando = false;

  @override
  void dispose() {
    _codCtrl.dispose();
    _nomCtrl.dispose();
    _dirCtrl.dispose();
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
      direccion: _dirCtrl.text.trim().isNotEmpty ? _dirCtrl.text.trim() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Nueva Sede'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _codCtrl,
            decoration: const InputDecoration(labelText: 'Código de Sede (ej: SEDE-01)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nomCtrl,
            decoration: const InputDecoration(labelText: 'Nombre de la Sede'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _dirCtrl,
            decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
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
          child: const Text('Guardar Sede'),
        ),
      ],
    );
  }
}
