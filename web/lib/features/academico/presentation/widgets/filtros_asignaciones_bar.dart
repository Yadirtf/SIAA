import 'package:flutter/material.dart';

import '../../data/models/academico_models.dart';
import '../helpers/filtro_asignaciones.dart';

/// Barra de filtros de asignaciones: periodo, día y búsqueda libre.
class FiltrosAsignacionesBar extends StatelessWidget {
  final List<PeriodoModel> periodos;
  final FiltroAsignaciones filtro;
  final ValueChanged<FiltroAsignaciones> onCambio;
  final int resultados;

  const FiltrosAsignacionesBar({
    super.key,
    required this.periodos,
    required this.filtro,
    required this.onCambio,
    required this.resultados,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: DropdownButtonFormField<String?>(
            initialValue: filtro.periodoId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Periodo',
              prefixIcon: Icon(Icons.calendar_month_outlined),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              for (final p in periodos)
                DropdownMenuItem(
                  value: p.id,
                  child: Text(
                    '${p.codigo} - ${p.nombre}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => onCambio(filtro.copiar(periodoId: () => v)),
          ),
        ),
        SizedBox(
          width: 210,
          child: DropdownButtonFormField<int?>(
            initialValue: filtro.dia,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Día',
              prefixIcon: Icon(Icons.today_outlined),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              for (var d = 1; d <= 7; d++)
                DropdownMenuItem(value: d, child: Text(nombreDia(d))),
            ],
            onChanged: (v) => onCambio(filtro.copiar(dia: () => v)),
          ),
        ),
        SizedBox(
          width: 320,
          child: TextFormField(
            initialValue: filtro.texto,
            decoration: const InputDecoration(
              labelText: 'Buscar docente, asignatura, grupo o aula',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
            onChanged: (v) => onCambio(filtro.copiar(texto: v)),
          ),
        ),
        Text('$resultados asignaciones'),
      ],
    );
  }
}
