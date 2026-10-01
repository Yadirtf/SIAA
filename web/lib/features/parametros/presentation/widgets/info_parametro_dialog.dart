import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/catalogo_parametros.dart';
import '../../domain/models/parametro_model.dart';

/// Explica un parámetro: qué controla, cómo se aplica, el rango permitido y
/// de qué nivel viene el valor que rige en el ámbito elegido.
Future<void> mostrarInfoParametro(
  BuildContext context,
  ParametroEfectivoModel parametro,
) => showDialog<void>(
  context: context,
  builder: (_) => InfoParametroDialog(parametro: parametro),
);

/// Aviso corto (chip) para parámetros que no se usan todavía o son institucionales.
class AvisoParametro extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color fondo;
  final Color color;

  const AvisoParametro.noAplicado({super.key})
    : texto = 'Todavía no se aplica',
      icono = Icons.hourglass_empty_rounded,
      fondo = AppColors.statusWarningBg,
      color = AppColors.statusWarningText;

  const AvisoParametro.soloGlobal({super.key})
    : texto = 'Solo en Global',
      icono = Icons.public_rounded,
      fondo = AppColors.statusInfoBg,
      color = AppColors.statusInfoText;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: fondo,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class InfoParametroDialog extends StatelessWidget {
  final ParametroEfectivoModel parametro;

  const InfoParametroDialog({super.key, required this.parametro});

  Widget _seccion(String titulo, String texto, IconData icono) {
    if (texto.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: AppColors.primaryAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(texto, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = infoParametro(parametro.clave);
    final limites = [
      if (info.esNumerico) info.rangoTexto,
      if (info.opciones.isNotEmpty)
        'Opciones: ${info.opciones.values.join(', ')}',
      'Valor por defecto: ${info.formatear(info.porDefecto)}',
    ].join('. ');
    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryAccent,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(info.nombre, style: AppTextStyles.h3)),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (!info.aplicado) const AvisoParametro.noAplicado(),
                  if (info.soloGlobal) const AvisoParametro.soloGlobal(),
                ],
              ),
              if (!info.aplicado || info.soloGlobal) const SizedBox(height: 12),
              _seccion('Para qué sirve', info.resumen, Icons.flag_outlined),
              _seccion(
                'Cómo funciona',
                info.comoFunciona,
                Icons.settings_suggest_outlined,
              ),
              _seccion(
                'Recomendación',
                info.recomendacion,
                Icons.lightbulb_outline_rounded,
              ),
              _seccion('Valores permitidos', limites, Icons.straighten_rounded),
              _seccion(
                'Cuándo surte efecto',
                info.cuandoAplica,
                Icons.event_repeat_rounded,
              ),
              _seccion(
                'Valor que rige ahora',
                '${info.formatear(parametro.valor)}, definido en el nivel '
                    '${parametro.nivelLabel}. Los niveles más específicos '
                    '(Sede, Facultad, Bloque, Aula) reemplazan al general.',
                Icons.account_tree_outlined,
              ),
              Text(
                'Clave técnica: ${parametro.clave}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}
