// destino_notificacion.dart — Traduce data.ruta de una notificación a un destino (US-NOT-01/02, US-MAR-12)
import 'package:equatable/equatable.dart';

enum PantallaNotificacion { marcaje, justificaciones, horario }

class DestinoNotificacion extends Equatable {
  final PantallaNotificacion pantalla;
  final String? sesionId;
  final String? justificacionId;

  const DestinoNotificacion(
    this.pantalla, {
    this.sesionId,
    this.justificacionId,
  });

  static const _rutas = {
    '/marcaje': PantallaNotificacion.marcaje,
    '/justificaciones': PantallaNotificacion.justificaciones,
    '/horario': PantallaNotificacion.horario,
  };

  /// Ruta del shell que aloja la pantalla destino.
  String get rutaShell {
    switch (pantalla) {
      case PantallaNotificacion.marcaje:
        return '/shell/inicio';
      case PantallaNotificacion.justificaciones:
        return '/shell/justificaciones';
      case PantallaNotificacion.horario:
        return '/shell/horario';
    }
  }

  /// Interpreta `datos` del payload FCM o de la bandeja; null si la ruta no se reconoce.
  static DestinoNotificacion? desdeDatos(Map<String, dynamic>? datos) {
    if (datos == null) return null;
    final ruta = datos['ruta'];
    final pantalla = ruta is String ? _rutas[ruta.trim()] : null;
    if (pantalla == null) return null;
    String? texto(Object? v) =>
        v is String && v.isNotEmpty ? v : (v == null ? null : '$v');
    return DestinoNotificacion(
      pantalla,
      sesionId: texto(datos['sesionId']),
      justificacionId: texto(datos['justificacionId']),
    );
  }

  @override
  List<Object?> get props => [pantalla, sesionId, justificacionId];
}
