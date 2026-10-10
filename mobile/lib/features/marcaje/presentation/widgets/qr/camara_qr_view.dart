// camara_qr_view.dart — Vista de cámara que lee el QR del aula con mobile_scanner
// Es el único punto que toca el plugin de cámara; las pruebas lo sustituyen por un doble.
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Construye la vista de cámara: [onCodigo] recibe el texto del QR y [onError]
/// el motivo legible si la cámara no está disponible o se negó el permiso.
typedef ConstructorCamaraQr = Widget Function(
  void Function(String crudo) onCodigo,
  void Function(String motivo) onError,
);

class CamaraQrView extends StatefulWidget {
  final void Function(String crudo) onCodigo;
  final void Function(String motivo) onError;

  const CamaraQrView({
    super.key,
    required this.onCodigo,
    required this.onError,
  });

  static Widget construir(
    void Function(String) onCodigo,
    void Function(String) onError,
  ) =>
      CamaraQrView(onCodigo: onCodigo, onError: onError);

  static String motivoDe(MobileScannerErrorCode codigo) {
    switch (codigo) {
      case MobileScannerErrorCode.permissionDenied:
        return 'No se concedió el permiso de cámara.';
      case MobileScannerErrorCode.unsupported:
        return 'Este dispositivo no tiene una cámara compatible.';
      default:
        return 'No se pudo abrir la cámara.';
    }
  }

  @override
  State<CamaraQrView> createState() => _CamaraQrViewState();
}

class _CamaraQrViewState extends State<CamaraQrView> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _errorAvisado = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _detectado(BarcodeCapture captura) {
    for (final b in captura.barcodes) {
      final v = b.rawValue;
      if (v != null && v.trim().isNotEmpty) {
        widget.onCodigo(v);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: _detectado,
      errorBuilder: (context, error) {
        if (!_errorAvisado) {
          _errorAvisado = true;
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => widget.onError(CamaraQrView.motivoDe(error.errorCode)));
        }
        return const ColoredBox(color: Colors.black);
      },
    );
  }
}
