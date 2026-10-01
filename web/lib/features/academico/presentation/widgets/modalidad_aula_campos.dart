import 'package:flutter/material.dart';

import '../../../geo/presentation/widgets/selector_espacio.dart';

/// Modalidad de la asignación y, si no es virtual, el aula de la sede del periodo.
class ModalidadAulaCampos extends StatelessWidget {
  final String modalidad;
  final String? periodoId;
  final String? sedeId;
  final String? espacioInicial;
  final ValueChanged<String> onModalidad;
  final ValueChanged<String?> onEspacio;

  const ModalidadAulaCampos({
    super.key,
    required this.modalidad,
    required this.periodoId,
    required this.sedeId,
    required this.onModalidad,
    required this.onEspacio,
    this.espacioInicial,
  });

  @override
  Widget build(BuildContext context) {
    final virtual = modalidad == 'VIRTUAL';
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: modalidad,
          decoration: const InputDecoration(
            labelText: 'Modalidad *',
            prefixIcon: Icon(Icons.settings_ethernet_rounded),
          ),
          items: const [
            DropdownMenuItem(value: 'PRESENCIAL', child: Text('Presencial')),
            DropdownMenuItem(value: 'VIRTUAL', child: Text('Virtual')),
            DropdownMenuItem(value: 'HIBRIDA', child: Text('Híbrida')),
          ],
          onChanged: (val) => onModalidad(val ?? 'PRESENCIAL'),
        ),
        if (!virtual) ...[
          const SizedBox(height: 12),
          SelectorEspacio(
            // Nueva instancia al cambiar de periodo: la sede puede cambiar.
            key: ValueKey('aula-$periodoId'),
            etiqueta: 'Aula *',
            sedeId: sedeId,
            idInicial: espacioInicial,
            requerido: true,
            onCambio: (e) => onEspacio(e?.id),
          ),
        ],
      ],
    );
  }
}
