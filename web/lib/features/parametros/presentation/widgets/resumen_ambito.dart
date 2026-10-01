import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/catalogo_parametros.dart';
import '../../domain/models/parametro_model.dart';
import 'linea_tiempo_clase.dart';

/// Vista rápida del ámbito: cómo queda una clase con estos valores y cuántos
/// parámetros tienen valor propio aquí.
class ResumenAmbito extends StatelessWidget {
  final List<ParametroEfectivoModel> parametros;
  final String ambito;
  final String nombreAmbito;

  const ResumenAmbito({
    super.key,
    required this.parametros,
    required this.ambito,
    required this.nombreAmbito,
  });

  Widget _tarjeta(String titulo, IconData icono, Widget hijo) => Card(
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: AppColors.primaryAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          hijo,
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final propios = parametros.where((p) => p.nivel == ambito).length;
    final sinUso = parametros.where((p) => !infoParametro(p.clave).aplicado);
    final linea = _tarjeta(
      'Así queda una clase con estos valores',
      Icons.timeline_rounded,
      LineaTiempoClase(v: VentanasEjemplo.desde(parametros)),
    );
    final resumen = _tarjeta(
      'Ámbito: $nombreAmbito',
      Icons.account_tree_outlined,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$propios de ${parametros.length}',
            style: AppTextStyles.h2.copyWith(color: AppColors.primaryAccent),
          ),
          Text(
            ambito == 'GLOBAL'
                ? 'parámetros con valor institucional.'
                : 'parámetros con valor propio aquí; el resto se hereda.',
            style: AppTextStyles.bodyMedium,
          ),
          if (sinUso.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${sinUso.length} parámetros se guardan pero el sistema '
              'todavía no los aplica (marcados "Todavía no se aplica").',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.statusWarningText,
              ),
            ),
          ],
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth < 900
          ? Column(children: [linea, const SizedBox(height: 12), resumen])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: linea),
                const SizedBox(width: 12),
                Expanded(child: resumen),
              ],
            ),
    );
  }
}
