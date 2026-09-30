// horario_event.dart - Eventos del BLoC de Mi Horario (US-ACA-01..09)
import 'package:equatable/equatable.dart';

abstract class HorarioEvent extends Equatable {
  const HorarioEvent();

  @override
  List<Object?> get props => [];
}

/// Carga la semana que contiene [fecha] (hoy por defecto) y selecciona ese día.
class CargarHorarioEvent extends HorarioEvent {
  final DateTime? fecha;
  final String? docenteId;

  const CargarHorarioEvent({this.fecha, this.docenteId});

  @override
  List<Object?> get props => [fecha, docenteId];
}

/// Selecciona un día de la semana ya cargada (sin nueva petición).
class CambiarDiaEvent extends HorarioEvent {
  final DateTime fecha;

  const CambiarDiaEvent(this.fecha);

  @override
  List<Object?> get props => [fecha];
}

/// Avanza (+1) o retrocede (-1) una semana.
class CambiarSemanaEvent extends HorarioEvent {
  final int desplazamiento;

  const CambiarSemanaEvent(this.desplazamiento);

  @override
  List<Object?> get props => [desplazamiento];
}

/// Recarga la semana visible conservando el día seleccionado.
class RecargarHorarioEvent extends HorarioEvent {
  const RecargarHorarioEvent();
}
