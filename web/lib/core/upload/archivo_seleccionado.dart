import 'dart:typed_data';

/// Archivo elegido por el usuario: nombre original y contenido.
class ArchivoSeleccionado {
  final String nombre;
  final Uint8List bytes;

  const ArchivoSeleccionado({required this.nombre, required this.bytes});
}
