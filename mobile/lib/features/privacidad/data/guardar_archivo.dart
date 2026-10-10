// guardar_archivo.dart — Guarda un archivo descargado donde el usuario elija (US-LEG-02 AC-01)
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Abre el diálogo del sistema para guardar el archivo; false si el usuario cancela.
Future<bool> guardarArchivoEnDispositivo(String nombre, Uint8List bytes) async {
  final destino = await FilePicker.saveFile(
    fileName: nombre,
    bytes: bytes,
    mimeType: 'application/json',
    dialogTitle: 'Guardar copia de mis datos',
  );
  return destino != null;
}
