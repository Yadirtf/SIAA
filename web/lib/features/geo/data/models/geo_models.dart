import 'package:equatable/equatable.dart';

class SedeModel extends Equatable {
  final String id;
  final String codigo;
  final String nombre;
  final String? direccion;
  final bool activo;

  const SedeModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.direccion,
    required this.activo,
  });

  factory SedeModel.fromJson(Map<String, dynamic> json) {
    return SedeModel(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      direccion: json['direccion']?.toString(),
      activo: json['activo'] == true,
    );
  }

  @override
  List<Object?> get props => [id, codigo, nombre, direccion, activo];
}

class BloqueModel extends Equatable {
  final String id;
  final String sedeId;
  final String codigo;
  final String nombre;
  final List<int> pisos;
  final bool activo;

  const BloqueModel({
    required this.id,
    required this.sedeId,
    required this.codigo,
    required this.nombre,
    required this.pisos,
    required this.activo,
  });

  factory BloqueModel.fromJson(Map<String, dynamic> json) {
    return BloqueModel(
      id: json['id']?.toString() ?? '',
      sedeId: json['sedeId']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      pisos: (json['pisos'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
      activo: json['activo'] == true,
    );
  }

  @override
  List<Object?> get props => [id, sedeId, codigo, nombre, pisos, activo];
}

class EspacioModel extends Equatable {
  final String id;
  final String sedeId;
  final String? torre;
  final String? bloqueId;
  final int? piso;
  final String codigo;
  final String nombre;
  final int capacidad;
  final String tipo;
  final String? facultadResponsable;
  final String estado;
  final double bufferMetros;
  final double areaMetrosCuadrados;
  final bool activo;

  const EspacioModel({
    required this.id,
    required this.sedeId,
    this.torre,
    this.bloqueId,
    this.piso,
    required this.codigo,
    required this.nombre,
    required this.capacidad,
    required this.tipo,
    this.facultadResponsable,
    required this.estado,
    required this.bufferMetros,
    required this.areaMetrosCuadrados,
    required this.activo,
  });

  factory EspacioModel.fromJson(Map<String, dynamic> json) {
    return EspacioModel(
      id: json['id']?.toString() ?? '',
      sedeId: json['sedeId']?.toString() ?? '',
      torre: json['torre']?.toString(),
      bloqueId: json['bloqueId']?.toString(),
      piso: json['piso'] != null ? (json['piso'] as num).toInt() : null,
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      capacidad: (json['capacidad'] as num?)?.toInt() ?? 0,
      tipo: json['tipo']?.toString() ?? 'AULA',
      facultadResponsable: json['facultadResponsable']?.toString(),
      estado: json['estado']?.toString() ?? 'DISPONIBLE',
      bufferMetros: (json['bufferMetros'] as num?)?.toDouble() ?? 0.0,
      areaMetrosCuadrados: (json['areaMetrosCuadrados'] as num?)?.toDouble() ?? 0.0,
      activo: json['activo'] == true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sedeId,
        torre,
        bloqueId,
        piso,
        codigo,
        nombre,
        capacidad,
        tipo,
        facultadResponsable,
        estado,
        bufferMetros,
        areaMetrosCuadrados,
        activo,
      ];
}

class SolapamientoItemModel extends Equatable {
  final String espacioAId;
  final String espacioANombre;
  final String espacioBId;
  final String espacioBNombre;
  final double areaInterseccion;
  final String tipoSeveridad;

  const SolapamientoItemModel({
    required this.espacioAId,
    required this.espacioANombre,
    required this.espacioBId,
    required this.espacioBNombre,
    required this.areaInterseccion,
    required this.tipoSeveridad,
  });

  factory SolapamientoItemModel.fromJson(Map<String, dynamic> json) {
    return SolapamientoItemModel(
      espacioAId: json['espacioAId']?.toString() ?? '',
      espacioANombre: json['espacioANombre']?.toString() ?? '',
      espacioBId: json['espacioBId']?.toString() ?? '',
      espacioBNombre: json['espacioBNombre']?.toString() ?? '',
      areaInterseccion: (json['areaInterseccion'] as num?)?.toDouble() ?? 0.0,
      tipoSeveridad: json['tipoSeveridad']?.toString() ?? 'ADVERTENCIA',
    );
  }

  @override
  List<Object?> get props => [
        espacioAId,
        espacioANombre,
        espacioBId,
        espacioBNombre,
        areaInterseccion,
        tipoSeveridad,
      ];
}
