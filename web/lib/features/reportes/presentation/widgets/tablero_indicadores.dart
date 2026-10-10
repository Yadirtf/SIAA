import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/tablero_model.dart';
import 'tarjeta_indicador.dart';

/// Indicadores del día del tablero en vivo (US-REP-03 AC-01).
class TableroIndicadores extends StatelessWidget {
  final TableroModel tablero;

  const TableroIndicadores({super.key, required this.tablero});

  @override
  Widget build(BuildContext context) {
    final t = tablero;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        TarjetaIndicador(
          icono: Icons.event_note_rounded,
          etiqueta: 'Sesiones del día',
          valor: '${t.sesionesDelDia}',
          detalle:
              '${t.sesionesFinalizadas} finalizadas · '
              '${t.sesionesCanceladas} canceladas',
        ),
        TarjetaIndicador(
          icono: Icons.play_circle_outline_rounded,
          etiqueta: 'Sesiones en curso',
          valor: '${t.sesionesEnCurso}',
          color: AppColors.accentCyan,
        ),
        TarjetaIndicador(
          icono: Icons.how_to_reg_rounded,
          etiqueta: 'Marcajes efectuados',
          valor: '${t.marcajesTotal}',
          color: AppColors.accentEmerald,
          detalle:
              '${t.entradasDocentes} entradas docentes · '
              '${t.entradasEstudiantes} estudiantes',
        ),
        TarjetaIndicador(
          icono: Icons.person_off_outlined,
          etiqueta: 'En curso sin marcaje',
          valor: '${t.sinMarcaje.length}',
          color: t.sinMarcaje.isEmpty
              ? AppColors.accentEmerald
              : AppColors.accentAmber,
        ),
        TarjetaIndicador(
          icono: Icons.notification_important_outlined,
          etiqueta: 'Alertas activas',
          valor: '${t.alertas.length}',
          color: t.alertas.isEmpty
              ? AppColors.accentEmerald
              : AppColors.accentRose,
        ),
      ],
    );
  }
}
