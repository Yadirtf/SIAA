// codigo_qr_aula.dart — Valor del QR fijo del aula leído por la cámara (US-GEO-13 AC-05)
// El QR impreso codifica el código del aula; si se imprimió como enlace
// (p. ej. https://…/aula?codigo=XYZ) se toma el parámetro "codigo" o "qr".
class CodigoQrAula {
  const CodigoQrAula._();

  static const _parametros = ['codigo', 'qr', 'qrCodigo'];

  /// Código a adjuntar al marcaje, o null si la lectura está vacía.
  static String? extraer(String? crudo) {
    final texto = crudo?.trim() ?? '';
    if (texto.isEmpty) return null;
    final uri = Uri.tryParse(texto);
    if (uri != null && uri.hasScheme && uri.queryParameters.isNotEmpty) {
      for (final p in _parametros) {
        final v = uri.queryParameters[p]?.trim();
        if (v != null && v.isNotEmpty) return v;
      }
    }
    return texto;
  }
}
