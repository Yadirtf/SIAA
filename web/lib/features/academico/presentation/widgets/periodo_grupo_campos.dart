import 'package:flutter/material.dart';

import '../../data/models/academico_models.dart';

/// Periodo y grupo de una asignación. Solo se listan los grupos del periodo,
/// con el nombre de su asignatura. Con [periodoFijo] el periodo no se cambia.
class PeriodoGrupoCampos extends StatelessWidget {
  final List<PeriodoModel> periodos;
  final List<GrupoModel> grupos;
  final List<AsignaturaModel> asignaturas;
  final String? periodoId;
  final String? grupoId;
  final bool periodoFijo;
  final ValueChanged<String?> onPeriodo;
  final ValueChanged<String?> onGrupo;

  const PeriodoGrupoCampos({
    super.key,
    required this.periodos,
    required this.grupos,
    required this.asignaturas,
    required this.periodoId,
    required this.grupoId,
    required this.onPeriodo,
    required this.onGrupo,
    this.periodoFijo = false,
  });

  String _etiquetaGrupo(GrupoModel g) {
    final asig = asignaturas.where((a) => a.id == g.asignaturaId);
    final nombre = asig.isEmpty ? 'Asignatura' : asig.first.nombre;
    return '$nombre · Grupo ${g.numero}';
  }

  @override
  Widget build(BuildContext context) {
    final delPeriodo = grupos.where((g) => g.periodoId == periodoId).toList();
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: periodoId,
          decoration: const InputDecoration(
            labelText: 'Periodo Académico *',
            prefixIcon: Icon(Icons.calendar_month_outlined),
          ),
          items: [
            for (final p in periodos)
              DropdownMenuItem(
                value: p.id,
                child: Text('${p.codigo} - ${p.nombre}'),
              ),
          ],
          onChanged: periodoFijo ? null : onPeriodo,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('grupos-$periodoId'),
          initialValue: delPeriodo.any((g) => g.id == grupoId) ? grupoId : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Grupo / Curso *',
            prefixIcon: const Icon(Icons.groups_outlined),
            helperText: delPeriodo.isEmpty
                ? 'Este periodo no tiene grupos'
                : null,
          ),
          items: [
            for (final g in delPeriodo)
              DropdownMenuItem(
                value: g.id,
                child: Text(_etiquetaGrupo(g), overflow: TextOverflow.ellipsis),
              ),
          ],
          validator: (v) => v == null ? 'Requerido' : null,
          onChanged: onGrupo,
        ),
      ],
    );
  }
}
