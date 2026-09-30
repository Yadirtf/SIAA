import 'package:equatable/equatable.dart';

abstract class DispositivosEvent extends Equatable {
  const DispositivosEvent();

  @override
  List<Object?> get props => [];
}

/// Solicita cargar los dispositivos vinculados a un usuario (GET /usuarios/:id/dispositivos).
class CargarDispositivosEvent extends DispositivosEvent {
  final String usuarioId;

  const CargarDispositivosEvent(this.usuarioId);

  @override
  List<Object?> get props => [usuarioId];
}

/// Solicita la aprobación de un dispositivo móvil (POST /dispositivos/:id/aprobar).
class AprobarDispositivoEvent extends DispositivosEvent {
  final String dispositivoId;
  final String usuarioId;

  const AprobarDispositivoEvent({
    required this.dispositivoId,
    required this.usuarioId,
  });

  @override
  List<Object?> get props => [dispositivoId, usuarioId];
}

/// Solicita revocar el acceso a un dispositivo móvil (POST /dispositivos/:id/revocar).
class RevocarDispositivoEvent extends DispositivosEvent {
  final String dispositivoId;
  final String usuarioId;
  final String? motivo;

  const RevocarDispositivoEvent({
    required this.dispositivoId,
    required this.usuarioId,
    this.motivo,
  });

  @override
  List<Object?> get props => [dispositivoId, usuarioId, motivo];
}

/// Limpia mensajes de notificación u operación.
class LimpiarMensajeDispositivoEvent extends DispositivosEvent {
  const LimpiarMensajeDispositivoEvent();
}
