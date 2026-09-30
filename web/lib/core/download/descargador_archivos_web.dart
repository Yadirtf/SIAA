import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

String _objectUrl(Uint8List bytes, String mime) {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mime),
  );
  return web.URL.createObjectURL(blob);
}

/// Descarga [bytes] como un archivo llamado [nombre] mediante un enlace
/// temporal con el atributo `download`.
void descargarArchivo(Uint8List bytes, String nombre, String mime) {
  final url = _objectUrl(bytes, mime);
  final enlace = web.HTMLAnchorElement()
    ..href = url
    ..download = nombre
    ..style.display = 'none';
  web.document.body?.append(enlace);
  enlace.click();
  enlace.remove();
  // Se libera después para no cancelar la descarga en curso.
  Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
}

/// Abre [bytes] en una pestaña nueva (p. ej. un PDF con el visor del
/// navegador). El object URL se libera pasado un minuto.
void abrirArchivo(Uint8List bytes, String mime) {
  final url = _objectUrl(bytes, mime);
  web.window.open(url, '_blank');
  Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
}
