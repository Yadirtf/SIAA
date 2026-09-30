import 'package:equatable/equatable.dart';

import '../../domain/models/parametro_model.dart';

/// Estados del BLoC de parametrización — consola web.
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
  final bool isSaving;
  final String? successMessage;
  final String? errorMessage;

  const ParametrosLoaded({
    required this.snapshot,
    this.isSaving = false,
    this.successMessage,
    this.errorMessage,
  });

  ParametrosLoaded copyWith({
    ParametrosSnapshot? snapshot,
    bool? isSaving,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
  }) {
    return ParametrosLoaded(
      snapshot: snapshot ?? this.snapshot,
      isSaving: isSaving ?? this.isSaving,
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [snapshot, isSaving, successMessage, errorMessage];
}

class ParametrosFailure extends ParametrosState {
  final String error;

  const ParametrosFailure({required this.error});

  @override
  List<Object?> get props => [error];
}
