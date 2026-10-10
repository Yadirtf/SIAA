import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/informe_generacion_model.dart';

/// Muestra el resultado de generar las sesiones de un periodo.
Future<void> mostrarInformeGeneracion(
  BuildContext context,
  InformeGeneracionModel informe,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Sesiones generadas', style: AppTextStyles.h3),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fila('Asignaciones procesadas', informe.asignacionesProcesadas),
              _fila('Sesiones nuevas', informe.sesionesGeneradas),
              _fila(
                'Ya existían (omitidas)',
                informe.sesionesOmitidasIdempotencia,
              ),
              if (informe.sesionesReactivadas > 0)
                _fila('Reactivadas', informe.sesionesReactivadas),
              _fila(
                'Fechas pasadas no generadas',
                informe.sesionesPasadasOmitidas,
              ),
              if (informe.sesionesPasadasOmitidas > 0)
                Text(
                  'Para crearlas, vuelva a generar marcando "Incluir fechas '
                  'pasadas".',
                  style: AppTextStyles.bodySmall,
                ),
              if (informe.asignacionesProcesadas == 0) ...[
                const SizedBox(height: 12),
                Text(
                  'El periodo no tiene asignaciones. Cree primero la '
                  'asignación del docente en "Asignaciones".',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
              ..._lista('Asignaciones omitidas', informe.asignacionesOmitidas),
              ..._lista('Fechas excluidas', informe.fechasExcluidas),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

Widget _fila(String etiqueta, int valor) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    children: [
      Expanded(child: Text(etiqueta, style: AppTextStyles.bodyMedium)),
      Text('$valor', style: AppTextStyles.h3),
    ],
  ),
);

List<Widget> _lista(String titulo, List<String> items) {
  if (items.isEmpty) return const [];
  return [
    const SizedBox(height: 12),
    Text(titulo, style: AppTextStyles.h3),
    const SizedBox(height: 4),
    for (final item in items.take(20))
      Text('• $item', style: AppTextStyles.bodySmall),
    if (items.length > 20)
      Text('… y ${items.length - 20} más', style: AppTextStyles.bodySmall),
  ];
}
