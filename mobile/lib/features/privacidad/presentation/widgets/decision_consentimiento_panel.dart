// decision_consentimiento_panel.dart — Botones explícitos Acepto / No acepto (US-LEG-01 AC-01)
import 'package:flutter/material.dart';
import '../../../../core/utils/fechas_es.dart';
import '../cubit/consentimiento_state.dart';

class DecisionConsentimientoPanel extends StatelessWidget {
  final ConsentimientoState state;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  const DecisionConsentimientoPanel({
    super.key,
    required this.state,
    required this.onAceptar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final c = state.consentimiento;
    final colores = Theme.of(context).colorScheme;
    final fecha = c?.decididoEn == null
        ? ''
        : ' el ${fechaHora(c!.decididoEn!)}';

    String? resumen;
    if (state.otorgado) {
      resumen = 'Aceptó la versión ${c!.versionVigente} del aviso$fecha.';
    } else if (state.rechazado) {
      resumen = 'No aceptó la versión ${c!.versionVigente}$fecha. El marcaje '
          'de asistencia está deshabilitado; puede aceptar cuando lo desee'
          '${state.contacto.isEmpty ? '' : ' o comunicarse con ${state.contacto}'}.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (resumen != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(resumen, style: TextStyle(color: colores.onSurface)),
          ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(state.error!, style: TextStyle(color: colores.error)),
          ),
        if (!state.otorgado)
          FilledButton.icon(
            onPressed: state.enviando ? null : onAceptar,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Acepto'),
          ),
        if (!state.rechazado) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: state.enviando ? null : onRechazar,
            child:
                Text(state.otorgado ? 'Retirar consentimiento' : 'No acepto'),
          ),
        ],
        if (state.enviando)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
