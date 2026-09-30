import 'dart:typed_data';

/// Archivo recibido como bytes (exportaciones, soportes), con su tipo MIME y
/// el nombre sugerido por `Content-Disposition` cuando el navegador lo expone.
class ArchivoBinario {
  final Uint8List bytes;
  final String mime;
  final String? nombre;

  const ArchivoBinario({required this.bytes, required this.mime, this.nombre});

  bool get esImagen => mime.startsWith('image/');
  bool get esPdf => mime == 'application/pdf';

  /// Extrae el nombre de una cabecera `Content-Disposition`
  /// (`attachment; filename="x.xlsx"` o `filename*=UTF-8''x.xlsx`).
  static String? nombreDesdeDisposition(String? disposition) {
    if (disposition == null || disposition.isEmpty) return null;
    final extendido = RegExp(
      r"filename\*\s*=\s*(?:UTF-8'')?([^;]+)",
      caseSensitive: false,
    ).firstMatch(disposition);
    if (extendido != null) {
      return Uri.decodeComponent(
        extendido.group(1)!.trim().replaceAll('"', ''),
      );
    }
    final simple = RegExp(
      r'filename\s*=\s*"?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(disposition);
    final nombre = simple?.group(1)?.trim();
    return nombre == null || nombre.isEmpty ? null : nombre;
  }
}
