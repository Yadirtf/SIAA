import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../data/models/asistencia_grupo_model.dart';

/// Porcentaje acumulado por estudiante; los que están bajo el umbral mínimo
/// se resaltan en rojo con un icono de alerta (US-REP-05 AC-02).
class AsistenciaGrupoTabla extends StatelessWidget {
  final ReporteAsistenciaGrupoModel reporte;

  const AsistenciaGrupoTabla({super.key, required this.reporte});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
          headingTextStyle: AppTextStyles.label,
          columns: const [
            DataColumn(label: Text('Estudiante')),
            DataColumn(label: Text('Documento')),
            DataColumn(label: Text('Dictadas'), numeric: true),
            DataColumn(label: Text('Asistidas'), numeric: true),
            DataColumn(label: Text('Asistencia'), numeric: true),
          ],
          rows: reporte.estudiantes.map(_fila).toList(),
        ),
      ),
    );
  }

  DataRow _fila(FilaEstudianteModel e) {
    final bajo = e.bajoUmbral;
    final estilo = AppTextStyles.bodyMedium.copyWith(
      color: bajo ? AppColors.statusDangerText : null,
      fontWeight: bajo ? FontWeight.w600 : null,
    );
    return DataRow(
      key: ValueKey('estudiante-${e.estudianteId}'),
      color: bajo ? WidgetStateProperty.all(AppColors.statusDangerBg) : null,
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (bajo) ...[
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: AppColors.statusDangerText,
                  semanticLabel: 'Bajo el umbral',
                ),
                const SizedBox(width: 6),
              ],
              Text(e.nombre.isEmpty ? e.estudianteId : e.nombre, style: estilo),
            ],
          ),
        ),
        DataCell(Text(e.documento, style: estilo)),
        DataCell(Text('${e.sesionesDictadas}', style: estilo)),
        DataCell(Text('${e.sesionesAsistidas}', style: estilo)),
        DataCell(Text(Formatos.porcentaje(e.porcentaje), style: estilo)),
      ],
    );
  }
}
