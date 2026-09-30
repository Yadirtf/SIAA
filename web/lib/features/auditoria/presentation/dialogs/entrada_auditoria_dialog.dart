import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../data/models/entrada_auditoria_model.dart';
import '../widgets/json_valor_view.dart';

/// Detalle de solo lectura de un registro de la bitácora.
class EntradaAuditoriaDialog extends StatelessWidget {
  final EntradaAuditoriaModel entrada;

  const EntradaAuditoriaDialog({super.key, required this.entrada});

  static Future<void> show(BuildContext context, EntradaAuditoriaModel e) =>
      showDialog<void>(
        context: context,
        builder: (_) => EntradaAuditoriaDialog(entrada: e),
      );

  Widget _dato(String etiqueta, String? valor) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: AppTextStyles.bodySmall),
          SelectableText(
            valor == null || valor.isEmpty ? '—' : valor,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = entrada;
    final ancho = MediaQuery.of(context).size.width >= 1000;
    final anterior = JsonValorView(
      titulo: 'Valor anterior',
      valor: e.valorAnterior,
    );
    final nuevo = JsonValorView(titulo: 'Valor nuevo', valor: e.valorNuevo);
    return AlertDialog(
      title: Text(e.accion),
      content: SizedBox(
        width: 960,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _dato('Fecha', Formatos.fechaHoraSegundos(e.creadoEn)),
                  _dato('Entidad', e.entidad),
                  _dato('Id de entidad', e.entidadId),
                  _dato('Actor', e.actor),
                  _dato('Id del actor', e.actorId),
                  _dato('Rol activo', e.rolActivo),
                  _dato('IP de origen', e.ipOrigen),
                  _dato('Correlation ID', e.correlationId),
                  _dato('Agente de usuario', e.agenteUsuario),
                ],
              ),
              const SizedBox(height: 20),
              if (ancho)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: anterior),
                    const SizedBox(width: 16),
                    Expanded(child: nuevo),
                  ],
                )
              else ...[
                anterior,
                const SizedBox(height: 16),
                nuevo,
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
