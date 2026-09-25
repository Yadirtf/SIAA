import 'package:equatable/equatable.dart';

abstract class GeoEvent extends Equatable {
  const GeoEvent();

  @override
  List<Object?> get props => [];
}

class LoadGeoDataEvent extends GeoEvent {
  final String? sedeId;
  final String? bloqueId;

  const LoadGeoDataEvent({this.sedeId, this.bloqueId});

  @override
  List<Object?> get props => [sedeId, bloqueId];
}

class CreateSedeEvent extends GeoEvent {
  final String codigo;
  final String nombre;
  final String? direccion;

  const CreateSedeEvent({
    required this.codigo,
    required this.nombre,
    this.direccion,
  });

  @override
  List<Object?> get props => [codigo, nombre, direccion];
}

class CreateBloqueEvent extends GeoEvent {
  final String sedeId;
  final String codigo;
  final String nombre;
  final List<int> pisos;

  const CreateBloqueEvent({
    required this.sedeId,
    required this.codigo,
    required this.nombre,
    required this.pisos,
  });

  @override
  List<Object?> get props => [sedeId, codigo, nombre, pisos];
}

class CreateEspacioEvent extends GeoEvent {
  final String sedeId;
  final String? bloqueId;
  final int? piso;
  final String codigo;
  final String nombre;
  final int capacidad;
  final String tipo;
  final String? facultadResponsable;

  const CreateEspacioEvent({
    required this.sedeId,
    this.bloqueId,
    this.piso,
    required this.codigo,
    required this.nombre,
    required this.capacidad,
    required this.tipo,
    this.facultadResponsable,
  });

  @override
  List<Object?> get props => [
    sedeId,
    bloqueId,
    piso,
    codigo,
    nombre,
    capacidad,
    tipo,
    facultadResponsable,
  ];
}

class DeleteEspacioEvent extends GeoEvent {
  final String id;
  const DeleteEspacioEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadSolapamientosEvent extends GeoEvent {
  final String? sedeId;
  const LoadSolapamientosEvent({this.sedeId});

  @override
  List<Object?> get props => [sedeId];
}
