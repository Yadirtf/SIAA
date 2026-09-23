import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardCargarDatosRequested extends DashboardEvent {
  const DashboardCargarDatosRequested();
}

class DashboardCambiarNavIndexRequested extends DashboardEvent {
  final int index;
  const DashboardCambiarNavIndexRequested(this.index);

  @override
  List<Object?> get props => [index];
}

class DashboardCrearSedeRequested extends DashboardEvent {
  final String codigo;
  final String nombre;
  final String? direccion;

  const DashboardCrearSedeRequested({
    required this.codigo,
    required this.nombre,
    this.direccion,
  });

  @override
  List<Object?> get props => [codigo, nombre, direccion];
}

class DashboardCrearBloqueRequested extends DashboardEvent {
  final String sedeId;
  final String codigo;
  final String nombre;
  final List<int> pisos;

  const DashboardCrearBloqueRequested({
    required this.sedeId,
    required this.codigo,
    required this.nombre,
    required this.pisos,
  });

  @override
  List<Object?> get props => [sedeId, codigo, nombre, pisos];
}

class DashboardCrearEspacioRequested extends DashboardEvent {
  final String sedeId;
  final String? bloqueId;
  final int piso;
  final String codigo;
  final String nombre;
  final int capacidad;
  final String tipo;

  const DashboardCrearEspacioRequested({
    required this.sedeId,
    this.bloqueId,
    required this.piso,
    required this.codigo,
    required this.nombre,
    required this.capacidad,
    required this.tipo,
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
      ];
}

class DashboardEliminarEspacioRequested extends DashboardEvent {
  final String espacioId;

  const DashboardEliminarEspacioRequested(this.espacioId);

  @override
  List<Object?> get props => [espacioId];
}

class DashboardLimpiarMensajesRequested extends DashboardEvent {
  const DashboardLimpiarMensajesRequested();
}
