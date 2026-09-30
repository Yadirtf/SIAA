/// Entrega de archivos al usuario desde bytes ya descargados con el token.
///
/// En web se crea un Blob y un object URL (package:web); en la VM de pruebas
/// se usa una implementación vacía.
library;

export 'descargador_archivos_stub.dart'
    if (dart.library.js_interop) 'descargador_archivos_web.dart';
