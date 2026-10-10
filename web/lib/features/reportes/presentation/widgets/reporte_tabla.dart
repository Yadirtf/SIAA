import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../data/models/fila_cumplimiento_model.dart';

/// Tabla de cumplimiento por docente con una fila final de totales. Las
/// filas por debajo del umbral de alerta se resaltan (US-PAR-04 AC-01).
class ReporteTabla extends StatelessWidget {
  final List<FilaCumplimientoModel> docentes;
  final FilaCumplimientoModel totales;

  /// Porcentaje mínimo de asistencia del ámbito; 0 si no se conoce.
  final double umbralAlerta;

  const ReporteTabla({
    super.key,
    required this.docentes,
    required this.totales,
    this.umbralAlerta = 0,
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
    ('Salidas faltantes', true),
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
    final fondo = esTotal
        ? AppColors.surfaceMuted
        : (f.bajoUmbral ? AppColors.statusDangerBg : null);
    return DataRow(
      key: esTotal ? null : ValueKey('fila-${f.docenteId}'),
      color: fondo == null ? null : WidgetStateProperty.all(fondo),
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
        DataCell(_salidas(f.salidasFaltantes, estilo)),
        DataCell(_porcentaje(f, estilo)),
      ],
    );
  }

  Widget _salidas(int n, TextStyle estilo) => Text(
    '$n',
    style: n > 0
        ? estilo.copyWith(
            color: AppColors.statusWarningText,
            fontWeight: FontWeight.w600,
          )
        : estilo,
  );

  /// Rojo bajo el umbral del ámbito; ámbar cerca de él (hasta 15 puntos
  /// por encima); verde en el resto.
  Widget _porcentaje(FilaCumplimientoModel f, TextStyle estilo) {
    final v = f.porcentajeCumplimiento;
    final umbral = umbralAlerta > 0 ? umbralAlerta : 75;
    final color = f.bajoUmbral || v < umbral
        ? AppColors.statusDangerText
        : v < umbral + 15
        ? AppColors.statusWarningText
        : AppColors.statusSuccessText;
    final texto = Text(
      Formatos.porcentaje(v),
      style: estilo.copyWith(color: color),
    );
    if (!f.bajoUmbral) return texto;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Por debajo del umbral de alerta',
          child: Icon(Icons.warning_amber_rounded, size: 16, color: color),
        ),
        const SizedBox(width: 4),
        texto,
      ],
    );
  }
}
