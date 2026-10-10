import 'package:flutter/material.dart';

/// Pregunta antes de abandonar el editor con cambios sin guardar
/// (US-GEO-07 AC-05). Devuelve `true` si el usuario decide descartarlos;
/// en ese caso no se envía nada al backend.
Future<bool> confirmarDescartarCambios(BuildContext context) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Descartar los cambios?'),
      content: const Text(
        'El polígono tiene ediciones sin guardar. Si sale ahora se pierden y '
        'la geometría guardada no cambia.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Seguir editando'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Descartar cambios'),
        ),
      ],
    ),
  );
  return r ?? false;
}
