import 'package:equatable/equatable.dart';

import '../../domain/models/dispositivo_model.dart';

abstract class DispositivosState extends Equatable {
  const DispositivosState();

  @override
  List<Object?> get props => [];
}

class DispositivosInitial extends DispositivosState {
  const DispositivosInitial();
}

class DispositivosLoading extends DispositivosState {
  const DispositivosLoading();
}

class DispositivosLoaded extends DispositivosState {
  final List<DispositivoModel> dispositivos;
  final String usuarioId;
  final String? actionSuccessMessage;
  final String? actionErrorMessage;
  final bool isProcessing;

  const DispositivosLoaded({
    required this.dispositivos,
    required this.usuarioId,
    this.actionSuccessMessage,
    this.actionErrorMessage,
    this.isProcessing = false,
  });

  int get total => dispositivos.length;
  int get aprobados => dispositivos.where((d) => d.esAprobado).length;
  int get pendientes => dispositivos.where((d) => d.esPendiente).length;
  int get revocados => dispositivos.where((d) => d.esRevocado).length;

  DispositivosLoaded copyWith({
    List<DispositivoModel>? dispositivos,
    String? usuarioId,
    String? actionSuccessMessage,
    String? actionErrorMessage,
    bool? isProcessing,
    bool clearMessages = false,
  }) {
    return DispositivosLoaded(
      dispositivos: dispositivos ?? this.dispositivos,
      usuarioId: usuarioId ?? this.usuarioId,
      actionSuccessMessage: clearMessages
          ? null
          : (actionSuccessMessage ?? this.actionSuccessMessage),
      actionErrorMessage: clearMessages
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  @override
  List<Object?> get props => [
    dispositivos,
    usuarioId,
    actionSuccessMessage,
    actionErrorMessage,
    isProcessing,
  ];
}

class DispositivosFailure extends DispositivosState {
  final String error;
  final String usuarioId;

  const DispositivosFailure({required this.error, this.usuarioId = ''});

  @override
  List<Object?> get props => [error, usuarioId];
}
