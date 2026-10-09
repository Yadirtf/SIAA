import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../data/models/ocupacion_model.dart';

/// Tabla de ocupación por aula, bloque o sede con fila de totales (US-REP-04).
class OcupacionTabla extends StatelessWidget {
  final ReporteOcupacionModel reporte;

  const OcupacionTabla({super.key, required this.reporte});

  static const _primera = {'aula': 'Aula', 'bloque': 'Bloque', 'sede': 'Sede'};

  @override
  Widget build(BuildContext context) {
    final agr = reporte.agrupacion;
    final columnas = <(String, bool)>[
      (_primera[agr] ?? 'Aula', false),
      if (agr == 'aula') ('Bloque', false),
      if (agr != 'sede') ('Sede', false),
      ('Espacios', true),
      ('Sesiones', true),
      ('Con asistencia', true),
      ('H. programadas', true),
      ('H. confirmadas', true),
      ('Utilización', true),
    ];
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
          columns: columnas
              .map((c) => DataColumn(label: Text(c.$1), numeric: c.$2))
              .toList(),
          rows: [
            ...reporte.filas.map((f) => _fila(f, agr)),
            _fila(reporte.totales, agr, esTotal: true),
          ],
        ),
      ),
    );
  }

  DataRow _fila(FilaOcupacionModel f, String agr, {bool esTotal = false}) {
    final estilo = esTotal
        ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)
        : AppTextStyles.bodyMedium;
    DataCell celda(String v) => DataCell(Text(v, style: estilo));
    final v = f.porcentajeUtilizacion;
    final color = v < 50
        ? AppColors.statusDangerText
        : v < 75
        ? AppColors.statusWarningText
        : AppColors.statusSuccessText;
    return DataRow(
      color: esTotal ? WidgetStateProperty.all(AppColors.surfaceMuted) : null,
      cells: [
        celda(esTotal ? 'TOTALES' : f.nombre),
        if (agr == 'aula') celda(esTotal ? '' : f.bloque),
        if (agr != 'sede') celda(esTotal ? '' : f.sede),
        celda('${f.espacios}'),
        celda('${f.sesiones}'),
        celda('${f.sesionesConfirmadas}'),
        celda(Formatos.decimal(f.horasProgramadas)),
        celda(Formatos.decimal(f.horasConfirmadas)),
        DataCell(
          Text(Formatos.porcentaje(v), style: estilo.copyWith(color: color)),
        ),
      ],
    );
  }
}
