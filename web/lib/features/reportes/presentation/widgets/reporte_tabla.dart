import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../data/models/fila_cumplimiento_model.dart';

/// Tabla de cumplimiento por docente con una fila final de totales.
class ReporteTabla extends StatelessWidget {
  final List<FilaCumplimientoModel> docentes;
  final FilaCumplimientoModel totales;

  const ReporteTabla({
    super.key,
    required this.docentes,
    required this.totales,
  });

  static const _columnas = [
    ('Docente', false),
    ('Documento', false),
    ('Sesiones', true),
    ('H. programadas', true),
    ('H. dictadas', true),
    ('H. justificadas', true),
    ('Presentes', true),
    ('Tardanzas', true),
    ('Aus. justificadas', true),
    ('Aus. injustificadas', true),
    ('Ajustadas', true),
    ('Cumplimiento', true),
  ];

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
          columnSpacing: 24,
          columns: _columnas
              .map((c) => DataColumn(label: Text(c.$1), numeric: c.$2))
              .toList(),
          rows: [
            ...docentes.map((d) => _fila(d)),
            _fila(totales, esTotal: true),
          ],
        ),
      ),
    );
  }

  DataRow _fila(FilaCumplimientoModel f, {bool esTotal = false}) {
    final estilo = esTotal
        ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)
        : AppTextStyles.bodyMedium;
    DataCell celda(String v) => DataCell(Text(v, style: estilo));
    return DataRow(
      color: esTotal ? WidgetStateProperty.all(AppColors.surfaceMuted) : null,
      cells: [
        celda(
          esTotal ? 'TOTALES' : (f.nombre.isEmpty ? f.docenteId : f.nombre),
        ),
        celda(esTotal ? '' : f.documento),
        celda('${f.sesiones}'),
        celda(Formatos.decimal(f.horasProgramadas)),
        celda(Formatos.decimal(f.horasDictadas)),
        celda(Formatos.decimal(f.horasJustificadas)),
        celda('${f.presentes}'),
        celda('${f.tardanzas}'),
        celda('${f.ausenciasJustificadas}'),
        celda('${f.ausenciasInjustificadas}'),
        celda('${f.ajustadas}'),
        DataCell(_porcentaje(f.porcentajeCumplimiento, estilo)),
      ],
    );
  }

  Widget _porcentaje(double v, TextStyle estilo) {
    final color = v >= 90
        ? AppColors.statusSuccessText
        : v >= 75
        ? AppColors.statusWarningText
        : AppColors.statusDangerText;
    return Text(Formatos.porcentaje(v), style: estilo.copyWith(color: color));
  }
}
