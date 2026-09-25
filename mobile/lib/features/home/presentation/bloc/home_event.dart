import 'package:equatable/equatable.dart';
import '../../../geo_editor/data/espacio_repository.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Solicitud de carga inicial o refresco de todas las sedes disponibles.
class CargarSedesRequested extends HomeEvent {
  const CargarSedesRequested();
}

/// Selección de una sede, disparando la carga de sus bloques asociados.
class SeleccionarSedeRequested extends HomeEvent {
  final SedeModel sede;

  const SeleccionarSedeRequested(this.sede);

  @override
  List<Object?> get props => [sede];
}

/// Selección de un bloque, disparando la carga de sus aulas/espacios asociados.
class SeleccionarBloqueRequested extends HomeEvent {
  final BloqueModel bloque;

  const SeleccionarBloqueRequested(this.bloque);

  @override
  List<Object?> get props => [bloque];
}

/// Creación de una nueva sede en backend MongoDB.
class CrearSedeRequested extends HomeEvent {
  final String codigo;
  final String nombre;
  final String? direccion;

  const CrearSedeRequested({
    required this.codigo,
    required this.nombre,
    this.direccion,
  });

  @override
  List<Object?> get props => [codigo, nombre, direccion];
}

/// Creación de un nuevo bloque en backend MongoDB.
class CrearBloqueRequested extends HomeEvent {
  final String sedeId;
  final String codigo;
  final String nombre;
  final List<int> pisos;

  const CrearBloqueRequested({
    required this.sedeId,
    required this.codigo,
    required this.nombre,
    required this.pisos,
  });

  @override
  List<Object?> get props => [sedeId, codigo, nombre, pisos];
}

/// Creación de una nueva aula o espacio físico en backend MongoDB.
class CrearEspacioRequested extends HomeEvent {
  final String sedeId;
  final String bloqueId;
  final String codigo;
  final String nombre;
  final int piso;
  final int capacidad;
  final String tipo;

  const CrearEspacioRequested({
    required this.sedeId,
    required this.bloqueId,
    required this.codigo,
    required this.nombre,
    required this.piso,
    required this.capacidad,
    required this.tipo,
  });

  @override
  List<Object?> get props =>
      [sedeId, bloqueId, codigo, nombre, piso, capacidad, tipo];
}

/// Recargar lista de aulas del bloque activo (ej. tras regresar del GeoEditor).
class RefrescarEspaciosRequested extends HomeEvent {
  const RefrescarEspaciosRequested();
}

/// Limpiar mensajes de notificación transitorios (SnackBar).
class LimpiarMensajesHomeRequested extends HomeEvent {
  const LimpiarMensajesHomeRequested();
}
