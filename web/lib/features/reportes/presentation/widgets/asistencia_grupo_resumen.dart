import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../data/models/asistencia_grupo_model.dart';
import 'tarjeta_indicador.dart';

/// Promedio del grupo, umbral y número de estudiantes bajo el umbral.
class AsistenciaGrupoResumen extends StatelessWidget {
  final ReporteAsistenciaGrupoModel reporte;

  const AsistenciaGrupoResumen({super.key, required this.reporte});

  @override
  Widget build(BuildContext context) {
    final r = reporte;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        TarjetaIndicador(
          icono: Icons.groups_2_outlined,
          etiqueta: 'Promedio del grupo',
          valor: Formatos.porcentaje(r.promedioGrupo),
          color: r.promedioGrupo < r.umbral
              ? AppColors.accentRose
              : AppColors.accentEmerald,
          detalle: '${r.estudiantes.length} estudiantes',
        ),
        TarjetaIndicador(
          icono: Icons.flag_outlined,
          etiqueta: 'Umbral mínimo',
          valor: '${r.umbral} %',
          detalle: '${r.sesionesDictadas} sesiones dictadas',
        ),
        TarjetaIndicador(
          icono: Icons.warning_amber_rounded,
          etiqueta: 'Bajo el umbral',
          valor: '${r.estudiantesBajoUmbral}',
          color: r.estudiantesBajoUmbral > 0
              ? AppColors.accentRose
              : AppColors.accentEmerald,
        ),
      ],
    );
  }
}
