// soporte_picker_service.dart — Captura de soportes: cámara, galería o PDF
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/justificacion_exception.dart';
import '../../domain/models/soporte_adjunto.dart';

/// Origen desde el que el docente adjunta un soporte.
enum OrigenSoporte { camara, galeria, pdf }

/// Abre el selector nativo y devuelve el archivo leído en memoria.
/// Devuelve `null` si el usuario cancela y lanza [JustificacionException]
/// si el archivo supera 10 MB (se verifica antes de leerlo en memoria).
class SoportePickerService {
  final ImagePicker _imagePicker;

  SoportePickerService({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  Future<SoporteAdjunto?> seleccionar(OrigenSoporte origen) {
    switch (origen) {
      case OrigenSoporte.camara:
        return _imagen(ImageSource.camera);
      case OrigenSoporte.galeria:
        return _imagen(ImageSource.gallery);
      case OrigenSoporte.pdf:
        return _pdf();
    }
  }

  Future<SoporteAdjunto?> _imagen(ImageSource source) async {
    // Re-codifica a JPEG comprimido para mantenerse bajo el límite de 10 MB.
    final foto = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2560,
      maxHeight: 2560,
      requestFullMetadata: false,
    );
    if (foto == null) return null;
    _verificarTamano(foto.name, await foto.length());
    return SoporteAdjunto(nombre: foto.name, bytes: await foto.readAsBytes());
  }

  Future<SoporteAdjunto?> _pdf() async {
    final archivo = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (archivo == null) return null;
    _verificarTamano(archivo.name, await archivo.length());
    final bytes = await archivo.xFile.readAsBytes();
    return SoporteAdjunto(nombre: archivo.name, bytes: bytes);
  }

  void _verificarTamano(String nombre, int? bytes) {
    if (bytes != null && bytes > ReglasSoporte.maxBytes) {
      throw JustificacionException(
        mensaje: 'El archivo "$nombre" supera 10 MB',
        codigo: 'SOPORTE_MUY_GRANDE',
      );
    }
  }
}
