import 'package:flutter/material.dart';

import '../../../../core/widgets/campo_fecha.dart';
import '../../../academico/data/models/academico_models.dart';
import '../../data/models/ocupacion_model.dart';

/// Filtros del reporte de ocupación: periodo o rango, y agrupación.
class OcupacionFiltros extends StatelessWidget {
  final FiltroOcupacionModel filtro;
  final List<PeriodoModel> periodos;
  final ValueChanged<FiltroOcupacionModel> onCambio;
  final ValueChanged<String> onAgrupar;
  final VoidCallback onConsultar;
  final bool consultando;

  const OcupacionFiltros({
    super.key,
    required this.filtro,
    required this.periodos,
    required this.onCambio,
    required this.onAgrupar,
    required this.onConsultar,
    this.consultando = false,
  });

  @override
  Widget build(BuildContext context) {
    final ids = periodos.map((p) => p.id).toSet();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<String?>(
            value: ids.contains(filtro.periodoId) ? filtro.periodoId : null,
            isExpanded: true,
            isDense: true,
            decoration: const InputDecoration(
              labelText: 'Periodo académico',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                child: Text('Sin periodo (usar fechas)'),
              ),
              ...periodos.map(
                (p) => DropdownMenuItem<String?>(
                  value: p.id,
                  child: Text(p.nombre, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (v) => onCambio(filtro.copyWith(periodoId: () => v)),
          ),
        ),
        CampoFecha(
          etiqueta: 'Desde',
          valor: filtro.desde,
          onCambio: (v) => onCambio(filtro.copyWith(desde: () => v)),
        ),
        CampoFecha(
          etiqueta: 'Hasta',
          valor: filtro.hasta,
          onCambio: (v) => onCambio(filtro.copyWith(hasta: () => v)),
        ),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'aula', label: Text('Por aula')),
            ButtonSegment(value: 'bloque', label: Text('Por bloque')),
            ButtonSegment(value: 'sede', label: Text('Por sede')),
          ],
          selected: {filtro.agrupacion},
          onSelectionChanged: (s) => onAgrupar(s.first),
        ),
        ElevatedButton.icon(
          onPressed: consultando ? null : onConsultar,
          icon: const Icon(Icons.search_rounded, size: 18),
          label: const Text('Consultar'),
        ),
      ],
    );
  }
}
