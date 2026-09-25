// horario_state.dart - Estados del BLoC de Mi Horario (US-ACA-01..09)
import 'package:equatable/equatable.dart';
import '../../data/models/sesion_horario_model.dart';

abstract class HorarioState extends Equatable {
  const HorarioState();

  @override
  List<Object?> get props => [];
}

class HorarioInitial extends HorarioState {
  const HorarioInitial();
}

class HorarioLoading extends HorarioState {
  const HorarioLoading();
}

class HorarioLoaded extends HorarioState {
  final List<SesionHorarioModel> sesiones;
  final DateTime fechaSeleccionada;
  final String? docenteId;

  const HorarioLoaded({
    required this.sesiones,
    required this.fechaSeleccionada,
    this.docenteId,
  });

  bool get esVacio => sesiones.isEmpty;

  @override
  List<Object?> get props => [sesiones, fechaSeleccionada, docenteId];
}

class HorarioError extends HorarioState {
  final String mensaje;

  const HorarioError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}
