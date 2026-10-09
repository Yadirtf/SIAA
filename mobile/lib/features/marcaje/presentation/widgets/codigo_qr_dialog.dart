// codigo_qr_dialog.dart — Lee el QR fijo del aula con la cámara (US-GEO-13 AC-05)
// Al detectar el QR el valor se devuelve de inmediato, sin pasos adicionales. Si la cámara
// no está disponible o se niega el permiso, el docente escribe el código impreso bajo el QR.
import 'package:flutter/material.dart';

import '../../domain/services/codigo_qr_aula.dart';
import 'qr/camara_qr_view.dart';

class CodigoQrDialog extends StatefulWidget {
  /// Se intentó otro método (WiFi o baliza) y no se pudo obtener.
  final bool otroMetodoIntentado;
  final ConstructorCamaraQr constructorCamara;

  const CodigoQrDialog({
    super.key,
    this.otroMetodoIntentado = false,
    this.constructorCamara = CamaraQrView.construir,
  });

  /// Devuelve el código leído o tecleado, o null si el docente cancela.
  static Future<String?> show(
    BuildContext context, {
    bool otroMetodoIntentado = false,
    ConstructorCamaraQr constructorCamara = CamaraQrView.construir,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CodigoQrDialog(
        otroMetodoIntentado: otroMetodoIntentado,
        constructorCamara: constructorCamara,
      ),
    );
  }

  @override
  State<CodigoQrDialog> createState() => _CodigoQrDialogState();
}

class _CodigoQrDialogState extends State<CodigoQrDialog> {
  final _controller = TextEditingController();
  bool _manual = false;
  bool _cerrado = false;
  String? _errorCamara;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _devolver(String? codigo) {
    if (_cerrado || !mounted) return;
    _cerrado = true;
    Navigator.of(context).pop(codigo);
  }

  void _qrLeido(String crudo) {
    final codigo = CodigoQrAula.extraer(crudo);
    if (codigo != null) _devolver(codigo);
  }

  void _camaraFallida(String motivo) {
    if (!mounted) return;
    setState(() {
      _errorCamara = motivo;
      _manual = true;
    });
  }

  void _confirmarManual() {
    final codigo = _controller.text.trim();
    if (codigo.isNotEmpty) _devolver(codigo);
  }

  String get _intro => widget.otroMetodoIntentado
      ? 'No fue posible verificar el aula por WiFi o Bluetooth. '
      : 'Esta aula exige verificación complementaria. ';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Verificación del aula'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _manual ? _vistaManual(tema) : _vistaCamara(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _devolver(null),
          child: const Text('Cancelar'),
        ),
        if (_manual)
          FilledButton(
            onPressed: _confirmarManual,
            child: const Text('Continuar'),
          ),
      ],
    );
  }

  List<Widget> _vistaCamara() => [
        Text('${_intro}Apunte la cámara al QR del aula; se adjuntará '
            'automáticamente.'),
        const SizedBox(height: 12),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox.square(
              dimension: 240,
              child: widget.constructorCamara(_qrLeido, _camaraFallida),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => setState(() => _manual = true),
          icon: const Icon(Icons.keyboard_alt_outlined),
          label: const Text('Escribir el código'),
        ),
      ];

  List<Widget> _vistaManual(ThemeData tema) => [
        if (_errorCamara != null) ...[
          Text(
            '$_errorCamara Escriba el código impreso bajo el QR del aula.',
            style: TextStyle(color: tema.colorScheme.error),
          ),
        ] else
          Text('${_intro}Escriba el código impreso bajo el QR del aula.'),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Código del QR',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _confirmarManual(),
        ),
        if (_errorCamara == null)
          TextButton.icon(
            onPressed: () => setState(() => _manual = false),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Escanear con la cámara'),
          ),
      ];
}
