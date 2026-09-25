// marcaje_event.dart — Eventos de BLoC de marcaje (US-MAR-01..US-MAR-15)
import 'package:equatable/equatable.dart';

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

  const RealizarMarcajeEvent({this.tipo = 'ENTRADA'});

  @override
  List<Object?> get props => [tipo];
}

class SincronizarOfflineEvent extends MarcajeEvent {
  const SincronizarOfflineEvent();
}
