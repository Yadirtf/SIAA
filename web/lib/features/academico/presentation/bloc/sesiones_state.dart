import 'package:equatable/equatable.dart';

import '../../data/models/sesion_model.dart';

abstract class SesionesState extends Equatable {
  const SesionesState();
  @override
  List<Object?> get props => [];
}

class SesionesInitial extends SesionesState {
  const SesionesInitial();
}

class SesionesLoading extends SesionesState {
  const SesionesLoading();
}

class SesionesLoaded extends SesionesState {
  final List<SesionModel> sesiones;
  final String? successMessage;

  /// Error de una acción (cancelar, reasignar); la tabla se conserva.
  final String? errorMessage;

  const SesionesLoaded(this.sesiones, {this.successMessage, this.errorMessage});

  @override
  List<Object?> get props => [sesiones, successMessage, errorMessage];
}

class SesionesError extends SesionesState {
  final String message;
  const SesionesError(this.message);

  @override
  List<Object?> get props => [message];
}
