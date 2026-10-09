// codigo_qr_dialog.dart — Solicita el código impreso en el QR del aula (verificación complementaria)
import 'package:flutter/material.dart';

// La app no incluye lector de QR por cámara (no hay paquete de escaneo en pubspec):
// el docente escribe el código impreso bajo el QR del aula (US-GEO-13 AC-05 parcial).
class CodigoQrDialog extends StatefulWidget {
  /// Se intentó leer el WiFi (y no se pudo) antes de pedir el código.
  final bool wifiIntentado;

  const CodigoQrDialog({super.key, this.wifiIntentado = false});

  /// Devuelve el código tecleado o null si el docente cancela.
  static Future<String?> show(BuildContext context,
      {bool wifiIntentado = false}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CodigoQrDialog(wifiIntentado: wifiIntentado),
    );
  }

  @override
  State<CodigoQrDialog> createState() => _CodigoQrDialogState();
}

class _CodigoQrDialogState extends State<CodigoQrDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    final codigo = _controller.text.trim();
    if (codigo.isEmpty) return;
    Navigator.of(context).pop(codigo);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Verificación del aula'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.wifiIntentado
                ? 'Esta aula exige verificación complementaria y no fue posible '
                    'identificar la red WiFi institucional. Escriba el código '
                    'impreso bajo el QR del aula.'
                : 'Esta aula exige verificación complementaria. Escriba el '
                    'código impreso bajo el QR del aula.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Código del QR',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _confirmar(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}
