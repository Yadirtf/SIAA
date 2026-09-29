import 'package:equatable/equatable.dart';

/// Fila del resultado de POST /usuarios/importar.
class FilaImportacionUsuarioModel extends Equatable {
  final int fila;
  final String correo;
  final String nombre;
  final bool valida;
  final bool creado;
  final String? error;
  final String? usuarioId;

  const FilaImportacionUsuarioModel({
    required this.fila,
    required this.correo,
    required this.nombre,
    required this.valida,
    required this.creado,
    this.error,
    this.usuarioId,
  });

  factory FilaImportacionUsuarioModel.fromJson(Map<String, dynamic> json) {
    final error = json['error']?.toString();
    return FilaImportacionUsuarioModel(
      fila: (json['fila'] as num?)?.toInt() ?? 0,
      correo: json['correo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      valida: json['valida'] == true,
      creado: json['creado'] == true,
      error: error == null || error.isEmpty ? null : error,
      usuarioId: json['usuarioId']?.toString(),
    );
  }

  @override
  List<Object?> get props => [fila, correo, nombre, valida, creado, error];
}

/// Resultado global de la importación (previa o confirmada).
class ImportacionUsuariosModel extends Equatable {
  final bool confirmado;
  final int total;
  final int validas;
  final int creados;
  final List<FilaImportacionUsuarioModel> filas;

  const ImportacionUsuariosModel({
    required this.confirmado,
    required this.total,
    required this.validas,
    required this.creados,
    required this.filas,
  });

  int get conError => total - validas;

  factory ImportacionUsuariosModel.fromJson(Map<String, dynamic> json) {
    final filas = json['filas'] is List
        ? (json['filas'] as List)
              .whereType<Map>()
              .map(
                (f) => FilaImportacionUsuarioModel.fromJson(
                  Map<String, dynamic>.from(f),
                ),
              )
              .toList()
        : <FilaImportacionUsuarioModel>[];
    return ImportacionUsuariosModel(
      confirmado: json['confirmado'] == true,
      total: (json['total'] as num?)?.toInt() ?? filas.length,
      validas: (json['validas'] as num?)?.toInt() ?? 0,
      creados: (json['creados'] as num?)?.toInt() ?? 0,
      filas: filas,
    );
  }

  @override
  List<Object?> get props => [confirmado, total, validas, creados, filas];
}
