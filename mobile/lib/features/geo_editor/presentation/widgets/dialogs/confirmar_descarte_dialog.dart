import 'package:flutter/material.dart';
import 'package:siaa_mobile/core/theme/app_theme.dart';

class ConfirmarDescarteDialog {
  static Future<bool> mostrar(BuildContext context) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SIAAColors.neutral900,
        title: const Text('¿Descartar cambios no guardados?'),
        content: const Text(
          'Tiene un levantamiento cartográfico en progreso. Si sale ahora, las modificaciones se perderán sin alterar el espacio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SIAAColors.asistenciaAusente,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Descartar y salir'),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }
}
