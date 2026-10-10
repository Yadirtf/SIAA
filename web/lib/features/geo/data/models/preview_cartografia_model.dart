import 'package:equatable/equatable.dart';

/// Un espacio detectado en el archivo GeoJSON/KML importado (US-GEO-11 AC-01).
class ItemCartografiaModel extends Equatable {
  final int indice;
  final String codigo;
  final String nombre;
  final String tipo;
  final bool valido;
  final bool coordenadasInvertidas;
  final List<String> errores;
  final List<String> advertencias;

  /// Elemento tal como lo devolvió el backend; se reenvía al confirmar y el
  /// backend lo revalida (no se confía en el veredicto del cliente).
  final Map<String, dynamic> crudo;

  const ItemCartografiaModel({
    required this.indice,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    required this.valido,
    required this.coordenadasInvertidas,
    required this.errores,
    required this.advertencias,
    required this.crudo,
  });

  factory ItemCartografiaModel.fromJson(Map<String, dynamic> json) {
    List<String> textos(Object? v) =>
        v is List ? v.map((e) => e.toString()).toList() : const [];
    return ItemCartografiaModel(
      indice: (json['indice'] as num?)?.toInt() ?? 0,
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'AULA',
      valido: json['valido'] == true,
      coordenadasInvertidas: json['coordenadasInvertidas'] == true,
      errores: textos(json['errores']),
      advertencias: textos(json['advertencias']),
      crudo: json,
    );
  }

  @override
  List<Object?> get props => [indice, codigo, valido, errores, advertencias];
}

/// Resultado de POST /espacios/importar/preview.
class PreviewCartografiaModel extends Equatable {
  final String formato;
  final int validos;
  final int invalidos;
  final List<ItemCartografiaModel> elementos;

  const PreviewCartografiaModel({
    required this.formato,
    required this.validos,
    required this.invalidos,
    required this.elementos,
  });

  factory PreviewCartografiaModel.fromJson(Map<String, dynamic> json) {
    final lista = json['elementos'];
    return PreviewCartografiaModel(
      formato: json['formato']?.toString() ?? 'geojson',
      validos: (json['validos'] as num?)?.toInt() ?? 0,
      invalidos: (json['invalidos'] as num?)?.toInt() ?? 0,
      elementos: lista is List
          ? lista
                .whereType<Map<String, dynamic>>()
                .map(ItemCartografiaModel.fromJson)
                .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [formato, validos, invalidos, elementos];
}

/// Resultado de POST /espacios/importar: creados y omitidos con su motivo.
class ResultadoImportacionCartografia extends Equatable {
  final int totalImportados;
  final List<String> omitidos;

  const ResultadoImportacionCartografia({
    required this.totalImportados,
    required this.omitidos,
  });

  factory ResultadoImportacionCartografia.fromJson(Map<String, dynamic> json) {
    final omitidos = json['omitidos'];
    return ResultadoImportacionCartografia(
      totalImportados: (json['totalImportados'] as num?)?.toInt() ?? 0,
      omitidos: omitidos is List
          ? omitidos
                .whereType<Map>()
                .map((o) => '${o['codigo']}: ${o['motivo']}')
                .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [totalImportados, omitidos];
}
