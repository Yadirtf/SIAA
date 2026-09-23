import 'package:flutter/material.dart';
import '../../../data/admin_geo_repository.dart';

class AdminEliminarEspacioDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AdminEspacio espacio,
    required VoidCallback onConfirmar,
  }) {
    return showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: Text('¿Eliminar espacio ${espacio.codigo}?'),
        content: const Text(
          'El espacio se marcará como inactivo (borrado lógico auditado).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(dlgContext).pop();
              onConfirmar();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
