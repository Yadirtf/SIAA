import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Diálogos modales para la gestión de solapamientos geográficos (US-GEO-05).
abstract class SolapamientoDialogs {
  /// US-GEO-05 AC-03: Bloqueo duro ante solapamiento mayor al 50%.
  static void mostrarCritico(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: const [
            Icon(Icons.block, color: SIAAColors.asistenciaAusente),
            SizedBox(width: 8),
            Text(
              'Solapamiento Crítico (>50%)',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          mensaje,
          style: const TextStyle(color: SIAAColors.neutral300, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Entendido', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  /// US-GEO-05 AC-01 & AC-02: Advertencia ante solapamiento <= 50% con confirmación auditada.
  static void mostrarAdvertencia(
    BuildContext context, {
    required String advertencia,
    List<String>? detalles,
    required void Function(String motivo) onConfirmar,
  }) {
    final motivoCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text(
              'Advertencia de Solapamiento',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              advertencia,
              style: const TextStyle(color: SIAAColors.neutral200, fontSize: 13),
            ),
            if (detalles != null && detalles.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...detalles.map(
                (d) => Text('• $d', style: const TextStyle(color: SIAAColors.neutral400, fontSize: 12)),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Indique el motivo para confirmar el guardado (quedará auditado):',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: motivoCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Ej. Tolerancia por muro divisorio compartido',
                hintStyle: TextStyle(color: SIAAColors.neutral500, fontSize: 12),
                filled: true,
                fillColor: Color(0xFF0F172A),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: SIAAColors.neutral400)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
            onPressed: () {
              final motivo = motivoCtrl.text.trim();
              Navigator.of(dialogCtx).pop();
              onConfirmar(motivo.isNotEmpty ? motivo : 'Confirmado por usuario en campo');
            },
            child: const Text('Confirmar y Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
