import 'package:flutter/material.dart';
import 'package:siaa_mobile/core/theme/app_theme.dart';

class EliminarVerticeDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required int verticeNumero,
    required VoidCallback onConfirmar,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SIAAColors.neutral900,
        title: Text('Eliminar vértice #$verticeNumero'),
        content: const Text(
          '¿Desea eliminar este vértice? (Solo permitido si el polígono conserva más de 3 vértices)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SIAAColors.asistenciaAusente,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirmar();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
