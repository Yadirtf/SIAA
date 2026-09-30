import '../network/archivo_binario.dart';
import 'descargador_archivos.dart';

/// Firma inyectable para entregar un archivo exportado al usuario; permite
/// sustituir la descarga del navegador en las pruebas.
typedef GuardarArchivo = void Function(ArchivoBinario archivo, String nombre);

/// Implementación por defecto: descarga en el navegador.
void guardarEnNavegador(ArchivoBinario archivo, String nombre) =>
    descargarArchivo(archivo.bytes, archivo.nombre ?? nombre, archivo.mime);

/// Nombre de respaldo para una exportación cuando el navegador no expone
/// `Content-Disposition` (CORS): `<prefijo>_AAAAMMDD_HHMM.<formato>`.
String nombreExportacion(String prefijo, String formato, DateTime ahora) {
  String dos(int n) => n.toString().padLeft(2, '0');
  final sello =
      '${ahora.year}${dos(ahora.month)}${dos(ahora.day)}_'
      '${dos(ahora.hour)}${dos(ahora.minute)}';
  return '${prefijo}_$sello.$formato';
}
