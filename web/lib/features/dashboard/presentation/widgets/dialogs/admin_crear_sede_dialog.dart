import 'package:flutter/material.dart';

class AdminCrearSedeDialog extends StatefulWidget {
  final void Function({
    required String codigo,
    required String nombre,
    String? direccion,
  }) onConfirmar;

  const AdminCrearSedeDialog({super.key, required this.onConfirmar});

  static Future<void> mostrar(
    BuildContext context, {
    required void Function({
      required String codigo,
      required String nombre,
      String? direccion,
    }) onConfirmar,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AdminCrearSedeDialog(onConfirmar: onConfirmar),
    );
  }

  @override
  State<AdminCrearSedeDialog> createState() => _AdminCrearSedeDialogState();
}

class _AdminCrearSedeDialogState extends State<AdminCrearSedeDialog> {
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Nueva Sede'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codigoCtrl,
              decoration: const InputDecoration(labelText: 'Código Sede (ej: SED-01)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre de la Sede'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _direccionCtrl,
              decoration: const InputDecoration(labelText: 'Dirección física'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final codigo = _codigoCtrl.text.trim();
            final nombre = _nombreCtrl.text.trim();
            final direccion = _direccionCtrl.text.trim();
            if (codigo.isEmpty || nombre.isEmpty) return;

            widget.onConfirmar(
              codigo: codigo,
              nombre: nombre,
              direccion: direccion.isEmpty ? null : direccion,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Crear Sede'),
        ),
      ],
    );
  }
}
