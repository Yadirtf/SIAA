import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/hora_12h.dart';
import '../helpers/filtro_asignaciones.dart';

/// Tabla de asignaciones con nombres legibles, ordenada por día y hora.
class TablaAsignaciones extends StatelessWidget {
  final List<FilaAsignacion> filas;
  final ValueChanged<FilaAsignacion> onEliminar;

  const TablaAsignaciones({
    super.key,
    required this.filas,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
            columns: const [
              DataColumn(label: Text('Día')),
              DataColumn(label: Text('Horario')),
              DataColumn(label: Text('Asignatura')),
              DataColumn(label: Text('Grupo')),
              DataColumn(label: Text('Docente')),
              DataColumn(label: Text('Aula')),
              DataColumn(label: Text('Modalidad')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: [for (final f in filas) _fila(f)],
          ),
        ),
      ),
    );
  }

  DataRow _fila(FilaAsignacion f) {
    final a = f.asignacion;
    return DataRow(
      cells: [
        DataCell(Text(nombreDia(a.diaSemana))),
        DataCell(
          Text(
            '${hora12hDesdeTexto(a.horaInicio)} - ${hora12hDesdeTexto(a.horaFin)}',
          ),
        ),
        DataCell(
          Text(
            f.asignatura,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(Text(f.grupo)),
        DataCell(Text(f.docente)),
        DataCell(Text(f.aula)),
        DataCell(Text(_modalidad(a.modalidad))),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.accentRose),
            tooltip: 'Eliminar asignación',
            onPressed: () => onEliminar(f),
          ),
        ),
      ],
    );
  }

  static String _modalidad(String m) => switch (m) {
    'VIRTUAL' => 'Virtual',
    'HIBRIDA' => 'Híbrida',
    _ => 'Presencial',
  };
}
