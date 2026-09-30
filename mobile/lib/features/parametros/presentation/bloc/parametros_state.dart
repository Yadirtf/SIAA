import 'package:equatable/equatable.dart';

import '../../domain/models/parametro_model.dart';

/// Estados del BLoC de parámetros en mobile.
abstract class ParametrosState extends Equatable {
  const ParametrosState();

  @override
  List<Object?> get props => [];
}

class ParametrosInitial extends ParametrosState {
  const ParametrosInitial();
}

class ParametrosLoading extends ParametrosState {
  const ParametrosLoading();
}

class ParametrosLoaded extends ParametrosState {
  final ParametrosSnapshot snapshot;

  /// Describe el ámbito para el cual se resolvió la cascada.
  final String ambitoLabel;

  const ParametrosLoaded({
    required this.snapshot,
    required this.ambitoLabel,
  });

  @override
  List<Object?> get props => [snapshot, ambitoLabel];
}

class ParametrosFailure extends ParametrosState {
  final String error;

  const ParametrosFailure({required this.error});

  @override
  List<Object?> get props => [error];
}
