import 'package:equatable/equatable.dart';

/// Motivo mínimo que exige el backend para cambiar una sesión puntual.
const minimoCaracteresMotivo = 5;

/// Datos comunes de un cambio puntual sobre una sesión (aula, suplente,
/// reprogramación): el motivo queda en la auditoría y `confirmar` acepta
/// cambiar una clase que ya comenzó (409 CONFIRMACION_REQUERIDA).
class CambioSesion extends Equatable {
  final String motivo;
  final bool confirmar;

  const CambioSesion({required this.motivo, this.confirmar = false});

  Map<String, dynamic> toJson() => {
    'motivo': motivo,
    if (confirmar) 'confirmar': true,
  };

  @override
  List<Object?> get props => [motivo, confirmar];
}

/// Nueva fecha y franja de una sesión reprogramada (US-ACA-06 AC-01).
class ReprogramacionSesion extends Equatable {
  /// AAAA-MM-DD.
  final String fecha;

  /// HH:mm en 24 h.
  final String horaInicio;
  final String horaFin;

  const ReprogramacionSesion({
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
  });

  Map<String, dynamic> toJson() => {
    'fecha': fecha,
    'horaInicio': horaInicio,
    'horaFin': horaFin,
  };

  @override
  List<Object?> get props => [fecha, horaInicio, horaFin];
}
