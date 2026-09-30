// marcaje_detalle_sheet.dart — Detalle de un marcaje con acciones de ajuste (US-MAR-09)
import 'package:flutter/material.dart';

import '../../../../core/utils/fechas_es.dart';
import '../../../marcaje/domain/models/marcaje_historial_model.dart';
import '../../../marcaje/presentation/widgets/resultado_badge.dart';

class MarcajeDetalleSheet extends StatelessWidget {
  final MarcajeHistorialItem item;

  /// Acciones visibles solo con marcaje:ajustar (el backend lo valida de nuevo).
  final VoidCallback? onAnular;
  final VoidCallback? onCorregir;

  const MarcajeDetalleSheet({
    super.key,
    required this.item,
    this.onAnular,
    this.onCorregir,
  });

  static Future<void> mostrar(BuildContext context, MarcajeDetalleSheet sheet) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filas = <(String, String)>[
      ('Persona', item.usuarioNombre.isEmpty ? '—' : item.usuarioNombre),
      ('Sesión', item.tituloSesion),
      ('Aula', item.espacioCodigo.isEmpty ? '—' : item.espacioCodigo),
      ('Tipo', item.tipo == 'SALIDA' ? 'Salida' : 'Entrada'),
      ('Resultado', etiquetaResultado(item.resultado)),
      ('Registrado', fechaHora(item.timestampServidor)),
      ('Hora del dispositivo', fechaHora(item.timestampDispositivo)),
      ('Origen', etiquetaOrigen(item.origen)),
      if (item.motivoRechazo != null)
        ('Motivo de rechazo', item.motivoRechazo!),
      if (item.precisionMetros > 0)
        ('Precisión GPS', '±${item.precisionMetros.toStringAsFixed(1)} m'),
      if (item.distanciaMetros != null)
        ('Distancia al aula', '${item.distanciaMetros!.toStringAsFixed(1)} m'),
      if (item.motivoAjuste != null) ('Motivo del ajuste', item.motivoAjuste!),
    ];
    final acciones = !item.anulado && (onAnular != null || onCorregir != null);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Detalle del marcaje',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ResultadoBadge(item: item),
              ],
            ),
            const SizedBox(height: 12),
            for (final (etiqueta, valor) in filas)
              _fila(context, etiqueta, valor),
            if (acciones) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onCorregir != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCorregir,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Corregir'),
                      ),
                    ),
                  if (onCorregir != null && onAnular != null)
                    const SizedBox(width: 12),
                  if (onAnular != null)
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700),
                        onPressed: onAnular,
                        icon: const Icon(Icons.block_rounded),
                        label: const Text('Anular'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fila(BuildContext context, String etiqueta, String valor) {
    final gris = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(etiqueta, style: TextStyle(fontSize: 13, color: gris)),
          ),
          Expanded(
            child: Text(valor,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
