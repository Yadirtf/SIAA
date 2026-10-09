// rectificacion_dialog.dart — Formulario de rectificación de datos (US-LEG-02 AC-02)
import 'package:flutter/material.dart';

/// Datos que el titular pide corregir y su explicación.
class PedidoRectificacion {
  final String descripcion;
  final Map<String, String> cambios;

  const PedidoRectificacion(this.descripcion, this.cambios);
}

class RectificacionDialog extends StatefulWidget {
  const RectificacionDialog({super.key});

  static Future<PedidoRectificacion?> mostrar(BuildContext context) =>
      showDialog<PedidoRectificacion>(
        context: context,
        builder: (_) => const RectificacionDialog(),
      );

  @override
  State<RectificacionDialog> createState() => _RectificacionDialogState();
}

class _RectificacionDialogState extends State<RectificacionDialog> {
  final _campos = {
    'nombre': TextEditingController(),
    'apellido': TextEditingController(),
    'documento': TextEditingController(),
  };
  final _descripcion = TextEditingController();
  String? _error;

  static const _etiquetas = {
    'nombre': 'Nombre correcto',
    'apellido': 'Apellido correcto',
    'documento': 'Documento correcto',
  };

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    _descripcion.dispose();
    super.dispose();
  }

  void _enviar() {
    final cambios = <String, String>{
      for (final e in _campos.entries)
        if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
    };
    final descripcion = _descripcion.text.trim();
    if (cambios.isEmpty) {
      setState(() => _error = 'Indique al menos un dato a corregir.');
      return;
    }
    if (descripcion.length < 10) {
      setState(() => _error = 'Explique la corrección (mínimo 10 caracteres).');
      return;
    }
    Navigator.pop(context, PedidoRectificacion(descripcion, cambios));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Solicitar rectificación'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final e in _campos.entries)
            TextField(
              controller: e.value,
              decoration: InputDecoration(labelText: _etiquetas[e.key]),
            ),
          TextField(
            controller: _descripcion,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Explicación',
              hintText: 'Qué dato está mal y por qué',
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ]),
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
