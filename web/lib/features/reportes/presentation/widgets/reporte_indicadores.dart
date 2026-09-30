import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../data/models/reporte_cumplimiento_model.dart';

/// Tarjetas con los indicadores globales del reporte.
class ReporteIndicadores extends StatelessWidget {
  final ReporteCumplimientoModel reporte;

  const ReporteIndicadores({super.key, required this.reporte});

  @override
  Widget build(BuildContext context) {
    final t = reporte.totales;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _Tarjeta(
          titulo: 'Cumplimiento',
          valor: Formatos.porcentaje(t.porcentajeCumplimiento),
          detalle:
              '${Formatos.decimal(t.horasDictadas)} de '
              '${Formatos.decimal(t.horasProgramadas)} h programadas',
          icono: Icons.verified_rounded,
          color: AppColors.accentEmerald,
        ),
        _Tarjeta(
          titulo: 'Tardanzas',
          valor: '${t.tardanzas}',
          detalle: '${t.sesiones} sesiones evaluadas',
          icono: Icons.timer_outlined,
          color: AppColors.accentAmber,
        ),
        _Tarjeta(
          titulo: 'Ausencias injustificadas',
          valor: '${t.ausenciasInjustificadas}',
          detalle: '${t.ausenciasJustificadas} ausencias justificadas',
          icono: Icons.event_busy_rounded,
          color: AppColors.accentRose,
        ),
        _Tarjeta(
          titulo: 'Falsos rechazos',
          valor: '${reporte.falsosRechazos}',
          detalle: 'Aprobadas por falla técnica',
          icono: Icons.report_gmailerrorred_rounded,
          color: AppColors.accentCyan,
        ),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final String titulo;
  final String valor;
  final String detalle;
  final IconData icono;
  final Color color;

  const _Tarjeta({
    required this.titulo,
    required this.valor,
    required this.detalle,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: AppTextStyles.bodySmall),
                Text(valor, style: AppTextStyles.h2),
                Text(
                  detalle,
                  style: AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
