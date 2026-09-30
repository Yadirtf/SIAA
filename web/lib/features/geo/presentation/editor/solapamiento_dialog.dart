import 'package:flutter/material.dart';

/// Pide confirmar un solapamiento con otra aula del mismo piso (US-GEO-05).
/// Devuelve el motivo escrito, o `null` si el usuario cancela.
Future<String?> pedirMotivoSolapamiento(BuildContext context, String aviso) {
  final motivo = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('El polígono se solapa con otra aula'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(aviso),
            const SizedBox(height: 12),
            TextField(
              controller: motivo,
              decoration: const InputDecoration(
                labelText: 'Motivo para guardarlo igual',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Corregir el dibujo'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            ctx,
            motivo.text.trim().isEmpty
                ? 'Confirmado en consola web'
                : motivo.text.trim(),
          ),
          child: const Text('Guardar igual'),
        ),
      ],
    ),
  );
}
