import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../parametros/domain/catalogo_parametros.dart';
import '../../data/models/sesion_model.dart';

/// Parámetros con que se generó la sesión. Los que ya no coinciden con la
/// cascada vigente se resaltan con el valor actual (US-PAR-03 AC-03): la
/// sesión sigue usando el congelado.
class ParametrosCongeladosLista extends StatelessWidget {
  final Map<String, dynamic> congelados;
  final List<DiferenciaParametro> diferentes;

  const ParametrosCongeladosLista({
    super.key,
    required this.congelados,
    this.diferentes = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (congelados.isEmpty) {
      return Text(
        'La sesión no tiene parámetros congelados registrados.',
        style: AppTextStyles.bodySmall,
      );
    }
    final porClave = {for (final d in diferentes) d.clave: d};
    final claves = congelados.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (diferentes.isNotEmpty) ...[
          _aviso(diferentes.length),
          const SizedBox(height: 8),
        ],
        for (final clave in claves)
          _fila(clave, congelados[clave], porClave[clave]),
      ],
    );
  }

  Widget _aviso(int n) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.statusWarningBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      n == 1
          ? '1 parámetro cambió después de generar la sesión. La sesión '
                'conserva el valor congelado.'
          : '$n parámetros cambiaron después de generar la sesión. La sesión '
                'conserva los valores congelados.',
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.statusWarningText,
      ),
    ),
  );

  Widget _fila(String clave, Object? valor, DiferenciaParametro? diferencia) {
    final info = infoParametro(clave);
    final cambia = diferencia != null;
    return Container(
      key: ValueKey('param-$clave'),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cambia ? AppColors.statusWarningBg : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(info.nombre, style: AppTextStyles.bodySmall)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  info.formatear(valor),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (cambia)
                  Text(
                    'Vigente hoy: ${info.formatear(diferencia.actual)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.statusWarningText,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
