// decision_revision_panel.dart — Botones de decisión según el estado (RF-JUS-002)
import 'package:flutter/material.dart';

class DecisionRevisionPanel extends StatelessWidget {
  final bool puedeTomar;
  final bool puedeDecidir;
  final bool procesando;
  final VoidCallback onTomar;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  const DecisionRevisionPanel({
    super.key,
    required this.puedeTomar,
    required this.puedeDecidir,
    required this.procesando,
    required this.onTomar,
    required this.onAprobar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    if (!puedeDecidir) return const SizedBox.shrink();
    if (procesando) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (puedeTomar)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onTomar,
                  icon: const Icon(Icons.pending_actions_rounded),
                  label: const Text('Tomar en revisión'),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700),
                    onPressed: onRechazar,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700),
                    onPressed: onAprobar,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Aprobar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
