/// Selección de un archivo local para subirlo (cargas masivas, US-ACA-07).
///
/// En web abre el diálogo nativo con un `<input type="file">` (package:web);
/// en la VM de pruebas no hay diálogo y devuelve `null`.
library;

export 'archivo_seleccionado.dart';
export 'selector_archivos_stub.dart'
    if (dart.library.js_interop) 'selector_archivos_web.dart';
