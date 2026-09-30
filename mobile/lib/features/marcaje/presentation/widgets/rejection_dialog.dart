// rejection_dialog.dart — Modal accionable con explicación estructurada y pasos de resolución (US-MAR-06)
import 'package:flutter/material.dart';
import '../../domain/models/marcaje_result_model.dart';

class RejectionDialog extends StatelessWidget {
  final MarcajeResultModel resultado;
  final VoidCallback? onReintentar;
  final VoidCallback? onJustificar;

  const RejectionDialog({
    super.key,
    required this.resultado,
    this.onReintentar,
    this.onJustificar,
  });

  static Future<void> show(
    BuildContext context, {
    required MarcajeResultModel resultado,
    VoidCallback? onReintentar,
    VoidCallback? onJustificar,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RejectionDialog(
        resultado: resultado,
        onReintentar: onReintentar,
        onJustificar: onJustificar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esPrec = resultado.esPrecisionInsuficiente;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            esPrec ? Icons.gps_not_fixed_rounded : Icons.cancel_outlined,
            color: esPrec ? Colors.amber.shade800 : Colors.red.shade700,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              esPrec ? 'Precisión Insuficiente' : 'Marcaje No Registrado',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              resultado.mensaje,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (resultado.distanciaMetros != null) ...[
              _buildMetricRow(
                'Distancia al aula:',
                '${resultado.distanciaMetros!.toStringAsFixed(1)} metros',
                Icons.straighten_rounded,
              ),
              const SizedBox(height: 6),
            ],
            if (resultado.precisionRecibida != null) ...[
              _buildMetricRow(
                'Precisión GPS:',
                '±${resultado.precisionRecibida!.toStringAsFixed(1)}m (mínima: 30m)',
                Icons.my_location_rounded,
              ),
              const SizedBox(height: 6),
            ],
            if (resultado.minutosRespectoInicio != 0) ...[
              _buildMetricRow(
                'Minutos desde inicio:',
                '${resultado.minutosRespectoInicio} min',
                Icons.schedule_rounded,
              ),
              const SizedBox(height: 6),
            ],
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue.shade800),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Sugerencia: Acérquese al centro del aula o hacia una ventana para refrescar la señal GPS.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (resultado.puedeJustificar)
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (onJustificar != null) onJustificar!();
            },
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Justificar'),
          ),
        if (resultado.permiteReintento)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (onReintentar != null) onReintentar!();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
