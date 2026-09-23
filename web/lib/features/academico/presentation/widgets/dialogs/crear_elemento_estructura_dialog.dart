import 'package:flutter/material.dart';

class CrearElementoEstructuraDialog extends StatefulWidget {
  final int activeLevel;
  final String? parentName;
  final Future<void> Function({required String codigo, required String nombre}) onGuardar;

  const CrearElementoEstructuraDialog({
    super.key,
    required this.activeLevel,
    this.parentName,
    required this.onGuardar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required int activeLevel,
    String? parentName,
    required Future<void> Function({required String codigo, required String nombre}) onGuardar,
  }) {
    return showDialog(
      context: context,
      builder: (_) => CrearElementoEstructuraDialog(
        activeLevel: activeLevel,
        parentName: parentName,
        onGuardar: onGuardar,
      ),
    );
  }

  @override
  State<CrearElementoEstructuraDialog> createState() => _CrearElementoEstructuraDialogState();
}

class _CrearElementoEstructuraDialogState extends State<CrearElementoEstructuraDialog> {
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String titulo = 'Nueva Facultad';
    if (widget.activeLevel == 1) titulo = 'Nuevo Programa para ${widget.parentName}';
    if (widget.activeLevel == 2) titulo = 'Nueva Asignatura para ${widget.parentName}';
    if (widget.activeLevel == 3) titulo = 'Nuevo Grupo para ${widget.parentName}';

    return AlertDialog(
      title: Text(titulo),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codigoCtrl,
              decoration: InputDecoration(
                labelText: widget.activeLevel == 3 ? 'Número de Grupo (ej. G01)*' : 'Código*',
                border: const OutlineInputBorder(),
              ),
            ),
            if (widget.activeLevel != 3) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre*',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (_codigoCtrl.text.trim().isEmpty) return;
            Navigator.of(context).pop();
            await widget.onGuardar(
              codigo: _codigoCtrl.text.trim(),
              nombre: _nombreCtrl.text.trim(),
            );
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
