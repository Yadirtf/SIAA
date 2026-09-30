// marcaje_event.dart — Eventos de BLoC de marcaje (US-MAR-01..US-MAR-15)
import 'package:equatable/equatable.dart';
import '../../domain/models/verificacion_complementaria_model.dart';

abstract class MarcajeEvent extends Equatable {
  const MarcajeEvent();

  @override
  List<Object?> get props => [];
}

class CargarSesionActivaEvent extends MarcajeEvent {
  const CargarSesionActivaEvent();
}

class CapturarUbicacionEvent extends MarcajeEvent {
  const CapturarUbicacionEvent();
}

class RealizarMarcajeEvent extends MarcajeEvent {
  final String tipo; // ENTRADA | SALIDA
  final VerificacionComplementariaModel? verificacion;

  const RealizarMarcajeEvent({this.tipo = 'ENTRADA', this.verificacion});

  @override
  List<Object?> get props => [tipo, verificacion];
}

class SincronizarOfflineEvent extends MarcajeEvent {
  const SincronizarOfflineEvent();
}

/// Relee la cola local (tras una sincronización lanzada fuera del BLoC).
class RefrescarColaOfflineEvent extends MarcajeEvent {
  const RefrescarColaOfflineEvent();
}

/// Reintento manual de un marcaje offline que agotó los reintentos automáticos.
class ReintentarMarcajeOfflineEvent extends MarcajeEvent {
  final String localId;

  const ReintentarMarcajeOfflineEvent(this.localId);

  @override
  List<Object?> get props => [localId];
}
