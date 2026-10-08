// ventana_estudiantil_card.dart — Elegir duración, abrir y cerrar el marcaje de los
// estudiantes del grupo con cuenta regresiva del servidor (US-MAR-13).
import 'package:flutter/material.dart';

import '../../../../../core/utils/fechas_es.dart';
import '../../cubit/marcaje_grupal_state.dart';
import 'cuenta_regresiva_ventana.dart';

class VentanaEstudiantilCard extends StatelessWidget {
  final MarcajeGrupalState state;
  final ValueChanged<int> onDuracion;
  final VoidCallback onAbrir;
  final VoidCallback onCerrar;
  final VoidCallback onVencida;

  const VentanaEstudiantilCard({
    super.key,
    required this.state,
    required this.onDuracion,
    required this.onAbrir,
    required this.onCerrar,
    required this.onVencida,
  });

  @override
  Widget build(BuildContext context) {
    final abierta = state.ventanaAbierta;
    final gris = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    final cierre = state.ventana.cierraEn;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(children: [
              Icon(Icons.groups_rounded, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text('Marcaje de estudiantes',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              abierta
                  ? 'Tus estudiantes pueden marcar desde su celular dentro del aula.'
                  : 'Habilita el marcaje para que tus estudiantes registren su asistencia desde su celular.',
              style: TextStyle(color: gris, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (abierta && cierre != null) ...[
              CuentaRegresivaVentana(
                cierraEn: cierre,
                ahora: () => state.ahora,
                onVencida: onVencida,
              ),
              const SizedBox(height: 4),
              Text('Hasta las ${hora12h(cierre)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: gris, fontSize: 12)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700),
                onPressed: state.procesando ? null : onCerrar,
                icon: const Icon(Icons.lock_rounded),
                label: const Text('Cerrar marcaje ahora'),
              ),
            ] else ...[
              if (!state.ventana.abierta && cierre != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                      'El último marcaje cerró a las ${hora12h(cierre)}.',
                      style: TextStyle(color: gris, fontSize: 12)),
                ),
              const Text('¿Cuánto tiempo lo dejas abierto?',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in MarcajeGrupalState.duraciones)
                    ChoiceChip(
                      label: Text('$m min'),
                      selected: state.duracionMinutos == m,
                      onSelected:
                          state.procesando ? null : (_) => onDuracion(m),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: state.procesando ? null : onAbrir,
                icon: state.procesando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.lock_open_rounded),
                label: Text('Abrir marcaje (${state.duracionMinutos} min)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
