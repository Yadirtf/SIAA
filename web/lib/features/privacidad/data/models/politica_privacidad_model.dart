import 'package:equatable/equatable.dart';

/// Aviso de privacidad vigente (Ley 1581 de 2012, RNF-LEG-003).
/// Refleja GET /privacidad/politica; `contenido` viene en Markdown.
class PoliticaPrivacidadModel extends Equatable {
  final String version;
  final String contenido;
  final String actualizadaEn;
  final String institucion;
  final String contacto;

  const PoliticaPrivacidadModel({
    required this.version,
    required this.contenido,
    this.actualizadaEn = '',
    this.institucion = '',
    this.contacto = '',
  });

  factory PoliticaPrivacidadModel.fromJson(Map<String, dynamic> json) {
    String texto(String clave) => json[clave]?.toString() ?? '';
    return PoliticaPrivacidadModel(
      version: texto('version'),
      contenido: texto('contenido'),
      actualizadaEn: texto('actualizadaEn'),
      institucion: texto('institucion'),
      contacto: texto('contacto'),
    );
  }

  @override
  List<Object?> get props => [
    version,
    contenido,
    actualizadaEn,
    institucion,
    contacto,
  ];
}
