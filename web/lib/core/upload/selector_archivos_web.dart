import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'archivo_seleccionado.dart';

/// Abre el selector del navegador y lee el archivo elegido; `null` si se cancela.
Future<ArchivoSeleccionado?> seleccionarArchivo({String accept = ''}) {
  final completer = Completer<ArchivoSeleccionado?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept;
  input.onchange = (web.Event _) {
    final archivo = input.files?.item(0);
    if (archivo == null) {
      completer.complete(null);
      return;
    }
    archivo.arrayBuffer().toDart.then(
      (buffer) => completer.complete(
        ArchivoSeleccionado(
          nombre: archivo.name,
          bytes: buffer.toDart.asUint8List(),
        ),
      ),
      onError: completer.completeError,
    );
  }.toJS;
  input.oncancel = (web.Event _) {
    if (!completer.isCompleted) completer.complete(null);
  }.toJS;
  input.click();
  return completer.future;
}
