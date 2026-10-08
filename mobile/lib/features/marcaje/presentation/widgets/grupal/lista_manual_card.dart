// lista_manual_card.dart — Acceso al pase de lista manual de contingencia (US-MAR-14)
import 'package:flutter/material.dart';

class ListaManualCard extends StatelessWidget {
  final VoidCallback onIniciar;

  const ListaManualCard({super.key, required this.onIniciar});

  @override
  Widget build(BuildContext context) {
    final gris = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(children: [
              Icon(Icons.checklist_rtl_rounded, color: Colors.teal),
              SizedBox(width: 8),
              Expanded(
                child: Text('Pase de lista manual',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              '¿Falló la red o algún estudiante no tiene celular? Registra la asistencia a mano; '
              'quienes ya marcaron conservan su registro.',
              style: TextStyle(color: gris, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onIniciar,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Tomar lista manual'),
            ),
          ],
        ),
      ),
    );
  }
}
