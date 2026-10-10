import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

/// Caja para pegar varios correos o documentos y agregarlos a la lista.
class AgregarEstudiantesBox extends StatefulWidget {
  /// Recibe el texto pegado y devuelve cuántos identificadores eran nuevos.
  final int Function(String texto) onAgregar;
  final bool habilitado;

  const AgregarEstudiantesBox({
    super.key,
    required this.onAgregar,
    this.habilitado = true,
  });

  @override
  State<AgregarEstudiantesBox> createState() => _AgregarEstudiantesBoxState();
}

class _AgregarEstudiantesBoxState extends State<AgregarEstudiantesBox> {
  final _ctrl = TextEditingController();
  String? _aviso;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _agregar() {
    if (_ctrl.text.trim().isEmpty) return;
    final n = widget.onAgregar(_ctrl.text);
    setState(() {
      _aviso = n == 0
          ? 'Esos identificadores ya estaban en la lista.'
          : 'Se agregaron $n a la lista. Pulse Guardar para aplicarlos.';
      if (n > 0) _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const Key('agregar-estudiantes'),
                controller: _ctrl,
                enabled: widget.habilitado,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Agregar estudiantes',
                  hintText:
                      'Correos o números de documento, uno por línea '
                      'o separados por coma',
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: widget.habilitado ? _agregar : null,
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
        if (_aviso != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_aviso!, style: AppTextStyles.bodySmall),
          ),
      ],
    );
  }
}
