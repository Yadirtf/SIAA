import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../data/models/justificacion_catalogos.dart';
import '../../data/models/justificacion_model.dart';
import 'justificacion_estado_badge.dart';

/// Datos principales de una justificación: sesión, docente, tipo,
/// descripción y observaciones del revisor.
class JustificacionResumen extends StatelessWidget {
  final JustificacionModel justificacion;
  final String Function(String id) nombreDe;

  const JustificacionResumen({
    super.key,
    required this.justificacion,
    required this.nombreDe,
  });

  Widget _dato(String etiqueta, Widget valor) {
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: AppTextStyles.bodySmall),
          const SizedBox(height: 2),
          valor,
        ],
      ),
    );
  }

  Widget _texto(String v) => Text(v, style: AppTextStyles.bodyMedium);

  Widget _bloque(String titulo, String texto) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: AppTextStyles.label),
          const SizedBox(height: 4),
          SelectableText(texto, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final j = justificacion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _dato('Docente', _texto(nombreDe(j.docenteId))),
            _dato('Sesión', _texto(j.nombreSesion ?? j.sesionId)),
            _dato(
              'Fecha de la sesión',
              _texto(j.fechaSesion.isEmpty ? '—' : j.fechaSesion),
            ),
            _dato('Tipo', _texto(JustificacionCatalogos.etiquetaTipo(j.tipo))),
            _dato('Estado', JustificacionEstadoBadge(estado: j.estado)),
            _dato('Radicada', _texto(Formatos.fechaHora(j.creadoEn))),
            if (j.revisorId != null)
              _dato('Revisor', _texto(nombreDe(j.revisorId!))),
          ],
        ),
        _bloque('Descripción', j.descripcion),
        if (j.observaciones != null)
          _bloque('Observaciones del revisor', j.observaciones!),
      ],
    );
  }
}
