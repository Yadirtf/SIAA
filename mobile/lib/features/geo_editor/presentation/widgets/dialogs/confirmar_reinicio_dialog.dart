import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Diálogo modal para confirmar el reinicio y descarte de los vértices capturados.
abstract class ConfirmarReinicioDialog {
  static void mostrar(BuildContext context,
      {required VoidCallback onConfirmar}) {
    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: const Text('¿Reiniciar polígono?'),
        content: const Text('Se descartarán todos los vértices capturados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: SIAAColors.asistenciaAusente),
            onPressed: () {
              Navigator.of(dlgContext).pop();
              onConfirmar();
            },
            child:
                const Text('Reiniciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
