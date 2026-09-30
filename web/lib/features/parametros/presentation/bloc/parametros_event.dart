import 'package:equatable/equatable.dart';

import '../../domain/models/parametro_model.dart';

/// Eventos del BLoC de parametrización — consola web.
abstract class ParametrosEvent extends Equatable {
  const ParametrosEvent();

  @override
  List<Object?> get props => [];
}

/// Carga los parámetros efectivos para el ámbito indicado (US-PAR-03).
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

/// Guarda un parámetro en el nivel indicado (US-PAR-01 AC-02).
class GuardarParametroEvent extends ParametrosEvent {
  final GuardarParametroRequest request;

  const GuardarParametroEvent({required this.request});

  @override
  List<Object?> get props => [request];
}

/// Limpia el mensaje de éxito/error de escritura.
class LimpiarMensajeParametroEvent extends ParametrosEvent {
  const LimpiarMensajeParametroEvent();
}
