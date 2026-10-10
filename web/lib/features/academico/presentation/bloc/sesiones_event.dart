import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../data/models/cambio_sesion.dart';

abstract class SesionesEvent extends Equatable {
  const SesionesEvent();
  @override
  List<Object?> get props => [];
}

class LoadSesionesEvent extends SesionesEvent {
  final String? periodoId;
  final String? docenteId;
  final String? espacioId;
  final String? fecha;
  final String? estado;

  /// Rango de fechas AAAA-MM-DD, inclusivo (la tabla consulta una semana).
  final String? desde;
  final String? hasta;

  const LoadSesionesEvent({
    this.periodoId,
    this.docenteId,
    this.espacioId,
    this.fecha,
    this.estado,
    this.desde,
    this.hasta,
  });

  @override
  List<Object?> get props => [
    periodoId,
    docenteId,
    espacioId,
    fecha,
    estado,
    desde,
    hasta,
  ];
}

/// Acción puntual sobre una sesión. Si trae [resultado], el diálogo espera
/// ahí la respuesta y explica él mismo el error (o pide confirmación), sin
/// que la pantalla muestre el aviso de error.
abstract class AccionSesionEvent extends SesionesEvent {
  final String sesionId;
  final Completer<void>? resultado;

  const AccionSesionEvent({required this.sesionId, this.resultado});
}

class CancelarSesionEvent extends AccionSesionEvent {
  final String motivo;

  const CancelarSesionEvent({
    required super.sesionId,
    required this.motivo,
    super.resultado,
  });

  @override
  List<Object?> get props => [sesionId, motivo];
}

class ReasignarAulaSesionEvent extends AccionSesionEvent {
  final String nuevoEspacioId;
  final CambioSesion cambio;

  const ReasignarAulaSesionEvent({
    required super.sesionId,
    required this.nuevoEspacioId,
    required this.cambio,
    super.resultado,
  });

  @override
  List<Object?> get props => [sesionId, nuevoEspacioId, cambio];
}

class AsignarDocenteReemplazoEvent extends AccionSesionEvent {
  final String docenteId;
  final CambioSesion cambio;

  const AsignarDocenteReemplazoEvent({
    required super.sesionId,
    required this.docenteId,
    required this.cambio,
    super.resultado,
  });

  @override
  List<Object?> get props => [sesionId, docenteId, cambio];
}

/// Mueve la sesión a otra fecha u hora (US-ACA-06 AC-01).
class ReprogramarSesionEvent extends AccionSesionEvent {
  final ReprogramacionSesion nueva;
  final CambioSesion cambio;

  const ReprogramarSesionEvent({
    required super.sesionId,
    required this.nueva,
    required this.cambio,
    super.resultado,
  });

  @override
  List<Object?> get props => [sesionId, nueva, cambio];
}
