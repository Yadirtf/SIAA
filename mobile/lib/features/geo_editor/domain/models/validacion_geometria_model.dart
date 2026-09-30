// Modelo de validacion geometrica seca - US-GEO-04 (T-GEO-04.3)
import 'package:equatable/equatable.dart';

/// Representa el resultado de la validacion topologica de un poligono.
class ValidacionGeometriaModel extends Equatable {
  final bool valido;
  final String codigo;
  final String mensaje;
  final double areaM2;
  final List<ConflictoSegmentoModel> conflictos;

  const ValidacionGeometriaModel({
    required this.valido,
    this.codigo = '',
    this.mensaje = '',
    this.areaM2 = 0.0,
    this.conflictos = const [],
  });

  factory ValidacionGeometriaModel.fromJson(Map<String, dynamic> json) {
    final conflictosRaw = json['conflictos'] as List<dynamic>? ?? [];
    return ValidacionGeometriaModel(
      valido: json['valido'] as bool? ?? false,
      codigo: json['codigo'] as String? ?? '',
      mensaje: json['mensaje'] as String? ?? '',
      areaM2: (json['areaM2'] as num?)?.toDouble() ?? 0.0,
      conflictos: conflictosRaw
          .map(
              (c) => ConflictoSegmentoModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'valido': valido,
        'codigo': codigo,
        'mensaje': mensaje,
        'areaM2': areaM2,
        'conflictos': conflictos.map((c) => c.toJson()).toList(),
      };

  @override
  List<Object?> get props => [valido, codigo, mensaje, areaM2, conflictos];
}

/// Representa un par de segmentos que intersectan o causan anomalia topologica.
class ConflictoSegmentoModel extends Equatable {
  final int indiceA;
  final int indiceB;
  final String tipo;
  final String descripcion;

  const ConflictoSegmentoModel({
    required this.indiceA,
    required this.indiceB,
    required this.tipo,
    required this.descripcion,
  });

  factory ConflictoSegmentoModel.fromJson(Map<String, dynamic> json) {
    return ConflictoSegmentoModel(
      indiceA: json['indiceA'] as int? ?? -1,
      indiceB: json['indiceB'] as int? ?? -1,
      tipo: json['tipo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'indiceA': indiceA,
        'indiceB': indiceB,
        'tipo': tipo,
        'descripcion': descripcion,
      };

  @override
  List<Object?> get props => [indiceA, indiceB, tipo, descripcion];
}
