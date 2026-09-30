import 'package:equatable/equatable.dart';

/// Eventos del BLoC de parámetros (mobile — solo lectura).
abstract class ParametrosEvent extends Equatable {
  const ParametrosEvent();

  @override
  List<Object?> get props => [];
}

/// Solicita los parámetros efectivos para un ámbito (US-PAR-03).
class CargarParametrosEfectivosEvent extends ParametrosEvent {
  final String? sedeId;
  final String? facultadId;
  final String? bloqueId;
  final String? espacioId;
  final String? asignacionId;

  const CargarParametrosEfectivosEvent({
    this.sedeId,
    this.facultadId,
    this.bloqueId,
    this.espacioId,
    this.asignacionId,
  });

  @override
  List<Object?> get props =>
      [sedeId, facultadId, bloqueId, espacioId, asignacionId];
}

/// Solicita solo los parámetros globales (valores por defecto del sistema).
class CargarParametrosGlobalesEvent extends ParametrosEvent {
  const CargarParametrosGlobalesEvent();
}
