import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../data/models/tablero_model.dart';

/// Contenedor con título para las listas del tablero.
class _Panel extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _Panel({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Sesiones en curso sin entrada del docente, con docente, aula y hora (AC-03).
class TableroSinMarcaje extends StatelessWidget {
  final List<SesionSinMarcajeModel> sesiones;

  const TableroSinMarcaje({super.key, required this.sesiones});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      titulo: 'Sesiones en curso sin marcaje',
      child: sesiones.isEmpty
          ? Text(
              'Todas las sesiones en curso tienen la entrada del docente.',
              style: AppTextStyles.bodyMedium,
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: AppTextStyles.label,
                columns: const [
                  DataColumn(label: Text('Docente')),
                  DataColumn(label: Text('Aula')),
                  DataColumn(label: Text('Asignatura')),
                  DataColumn(label: Text('Horario')),
                  DataColumn(label: Text('Transcurrido'), numeric: true),
                ],
                rows: sesiones
                    .map(
                      (s) => DataRow(
                        key: ValueKey('sin-marcaje-${s.sesionId}-${s.docenteId}'),
                        cells: [
                          DataCell(Text(s.docente)),
                          DataCell(Text(s.aula)),
                          DataCell(Text(s.asignatura)),
                          DataCell(Text('${s.horaInicio} – ${s.horaFin}')),
                          DataCell(Text('${s.minutosTranscurridos} min')),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}

/// Rachas de inasistencias consecutivas todavía abiertas.
class TableroAlertas extends StatelessWidget {
  final List<AlertaActivaModel> alertas;

  const TableroAlertas({super.key, required this.alertas});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      titulo: 'Alertas activas de inasistencias',
      child: alertas.isEmpty
          ? Text('No hay alertas activas.', style: AppTextStyles.bodyMedium)
          : Column(
              children: alertas
                  .map(
                    (a) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.accentRose,
                      ),
                      title: Text(a.docente.isEmpty ? a.docenteId : a.docente),
                      subtitle: Text(a.mensaje),
                      trailing: Text(
                        Formatos.fechaHora(a.creadaEn),
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
