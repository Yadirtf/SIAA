// conflicto_captura_dialog.dart — Decisión del usuario ante un conflicto (US-GEO-10 AC-04)
// El espacio cambió en el servidor después de la captura offline: nada se sobrescribe
// sin que el administrador elija.
import 'package:flutter/material.dart';

import '../../../../../core/geo/offline_cartografia_service.dart';

enum DecisionConflicto { mantenerMia, revisarEnEditor, descartarMia }

class ConflictoCapturaDialog {
  static Future<DecisionConflicto?> mostrar(
    BuildContext context,
    CapturaOfflineEspacio captura,
  ) {
    return showDialog<DecisionConflicto>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conflicto de geometría'),
        content: Text(
          'El espacio ${captura.espacioCodigo} fue modificado en el servidor '
          '(versión ${captura.versionServidor ?? '?'}) después de su captura '
          'sin conexión, hecha sobre la versión ${captura.versionEsperada}.\n\n'
          '¿Qué desea hacer con su captura de ${captura.vertices.length} vértices?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(DecisionConflicto.descartarMia),
            child: const Text('Conservar la del servidor'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(DecisionConflicto.revisarEnEditor),
            child: const Text('Revisar en el editor'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(DecisionConflicto.mantenerMia),
            child: const Text('Reemplazar con la mía'),
          ),
        ],
      ),
    );
  }
}
