// horario_event.dart - Eventos del BLoC de Mi Horario (US-ACA-01..09)
import 'package:equatable/equatable.dart';

abstract class HorarioEvent extends Equatable {
  const HorarioEvent();

  @override
  List<Object?> get props => [];
}

class CargarHorarioEvent extends HorarioEvent {
  final DateTime? fecha;
  final String? docenteId;

  const CargarHorarioEvent({this.fecha, this.docenteId});

  @override
  List<Object?> get props => [fecha, docenteId];
}

class CambiarDiaEvent extends HorarioEvent {
  final DateTime fecha;

  const CambiarDiaEvent(this.fecha);

  @override
  List<Object?> get props => [fecha];
}
