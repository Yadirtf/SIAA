import 'package:equatable/equatable.dart';

/// Soporte adjunto a una justificación (metadatos; el contenido se descarga
/// aparte por GET /justificaciones/{id}/soportes/{soporteId}).
class AdjuntoModel extends Equatable {
  final String id;
  final String nombre;
  final String mime;
  final int tamano;
  final String sha256;

  const AdjuntoModel({
    required this.id,
    required this.nombre,
    required this.mime,
    this.tamano = 0,
    this.sha256 = '',
  });

  bool get esImagen => mime.startsWith('image/');
  bool get esPdf => mime == 'application/pdf';

  /// Tamaño legible (B, KB, MB).
  String get tamanoTexto {
    if (tamano < 1024) return '$tamano B';
    if (tamano < 1024 * 1024) return '${(tamano / 1024).toStringAsFixed(1)} KB';
    return '${(tamano / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory AdjuntoModel.fromJson(Map<String, dynamic> json) => AdjuntoModel(
    id: json['id']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    mime: json['mime']?.toString() ?? '',
    tamano: (json['tamano'] as num?)?.toInt() ?? 0,
    sha256: json['sha256']?.toString() ?? '',
  );

  @override
  List<Object?> get props => [id, nombre, mime, tamano, sha256];
}
