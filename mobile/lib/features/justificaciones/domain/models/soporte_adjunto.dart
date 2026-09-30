// soporte_adjunto.dart — Archivo local elegido como soporte (RF-JUS-001)
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Reglas de soportes compartidas con el backend.
class ReglasSoporte {
  ReglasSoporte._();

  static const int maxBytes = 10 * 1024 * 1024;
  static const int maxArchivos = 3;
  static const int minDescripcion = 10;
  static const extensionesPermitidas = ['jpg', 'jpeg', 'png', 'pdf'];
}

/// Soporte local listo para enviarse en el campo multipart "soportes".
class SoporteAdjunto extends Equatable {
  final String nombre;
  final Uint8List bytes;

  const SoporteAdjunto({required this.nombre, required this.bytes});

  int get tamano => bytes.length;

  String get extension {
    final punto = nombre.lastIndexOf('.');
    return punto < 0 ? '' : nombre.substring(punto + 1).toLowerCase();
  }

  /// Tipo MIME declarado (el backend verifica el contenido real).
  String get mime {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }

  bool get esPdf => extension == 'pdf';

  /// Mensaje de error si el archivo no cumple las reglas; `null` si es válido.
  String? validar() {
    if (!ReglasSoporte.extensionesPermitidas.contains(extension)) {
      return 'El archivo "$nombre" no es JPG, PNG ni PDF';
    }
    if (tamano == 0) return 'El archivo "$nombre" está vacío';
    if (tamano > ReglasSoporte.maxBytes) {
      return 'El archivo "$nombre" supera 10 MB';
    }
    return null;
  }

  @override
  List<Object?> get props => [nombre, tamano];
}

/// Tamaño legible (KB/MB) para mostrar en la lista de adjuntos.
String formatearTamano(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
