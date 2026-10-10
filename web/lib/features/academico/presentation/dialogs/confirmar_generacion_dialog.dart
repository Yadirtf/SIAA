import 'package:flutter/material.dart';

import '../../data/models/academico_models.dart';

/// Pregunta antes de generar las sesiones de un periodo. Devuelve null si se
/// cancela, o si se incluyen las fechas que ya pasaron.
Future<bool?> confirmarGeneracion(BuildContext context, PeriodoModel periodo) =>
    showDialog<bool>(
      context: context,
      builder: (_) => ConfirmarGeneracionDialog(periodo: periodo),
    );

class ConfirmarGeneracionDialog extends StatefulWidget {
  final PeriodoModel periodo;

  const ConfirmarGeneracionDialog({super.key, required this.periodo});

  @override
  State<ConfirmarGeneracionDialog> createState() =>
      _ConfirmarGeneracionDialogState();
}

class _ConfirmarGeneracionDialogState extends State<ConfirmarGeneracionDialog> {
  bool _incluirPasadas = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.periodo;
    return AlertDialog(
      title: const Text('Generar sesiones'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se crearán las sesiones de todas las asignaciones de '
              '${p.nombre} entre ${p.fechaInicio} y ${p.fechaFin}. Las que ya '
              'existen no se duplican. La generación sigue en segundo plano.',
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _incluirPasadas,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Incluir fechas pasadas'),
              subtitle: const Text(
                'Por defecto solo se generan clases desde hoy.',
              ),
              onChanged: (v) => setState(() => _incluirPasadas = v ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _incluirPasadas),
          child: const Text('Generar'),
        ),
      ],
    );
  }
}
