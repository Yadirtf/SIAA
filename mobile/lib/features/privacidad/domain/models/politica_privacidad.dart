// politica_privacidad.dart — Aviso de privacidad vigente (US-LEG-01, RNF-LEG-001)
// Espejo de GET /privacidad/politica (endpoint público).
import 'package:equatable/equatable.dart';

class PoliticaPrivacidad extends Equatable {
  final String version;

  /// Texto del aviso en Markdown.
  final String contenido;
  final String actualizadaEn;
  final String institucion;

  /// Canal institucional para consultas y reclamos (Ley 1581/2012).
  final String contacto;

  const PoliticaPrivacidad({
    required this.version,
    required this.contenido,
    this.actualizadaEn = '',
    this.institucion = '',
    this.contacto = '',
  });

  factory PoliticaPrivacidad.fromJson(Map<String, dynamic> json) =>
      PoliticaPrivacidad(
        version: json['version'] as String? ?? '',
        contenido: json['contenido'] as String? ?? '',
        actualizadaEn: json['actualizadaEn'] as String? ?? '',
        institucion: json['institucion'] as String? ?? '',
        contacto: json['contacto'] as String? ?? '',
      );

  @override
  List<Object?> get props =>
      [version, contenido, actualizadaEn, institucion, contacto];
}
