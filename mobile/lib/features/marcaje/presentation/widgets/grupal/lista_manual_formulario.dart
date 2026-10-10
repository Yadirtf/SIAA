// lista_manual_formulario.dart — Motivo obligatorio y botón de guardar de la lista manual
// (US-MAR-14). El error del servidor se muestra tal cual llega en "mensaje".
import 'package:flutter/material.dart';

import '../../cubit/lista_manual_state.dart';

class ListaManualFormulario extends StatelessWidget {
  final ListaManualState state;
  final ValueChanged<String> onMotivo;
  final VoidCallback onEnviar;

  const ListaManualFormulario({
    super.key,
    required this.state,
    required this.onMotivo,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('motivoListaManual'),
            initialValue: state.motivo,
            enabled: !state.enviando,
            maxLines: 3,
            onChanged: onMotivo,
            decoration: InputDecoration(
              labelText: 'Motivo de la lista manual',
              hintText: 'Ej.: no había señal en el aula durante la clase.',
              border: const OutlineInputBorder(),
              errorText: state.motivoFaltante
                  ? 'Cuéntanos por qué tomas la lista a mano.'
                  : null,
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: state.puedeEnviar ? onEnviar : null,
            icon: state.enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_rounded),
            label: const Text('Guardar lista'),
          ),
        ],
      ),
    );
  }
}
