// notificacion_model.dart — Elemento de la bandeja de notificaciones (US-NOT-01/02)
// Espejo de GET /me/notificaciones.
import 'package:equatable/equatable.dart';
import 'destino_notificacion.dart';

class NotificacionModel extends Equatable {
  final String id;

  /// RECORDATORIO_SESION | CIERRE_VENTANA | RESULTADO_JUSTIFICACION | CAMBIO_HORARIO
  final String tipo;
  final String titulo;
  final String cuerpo;
  final Map<String, dynamic> datos;
  final DateTime? creadaEn;
  final bool leida;

  const NotificacionModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.cuerpo,
    this.datos = const {},
    this.creadaEn,
    this.leida = false,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    final datos = json['datos'];
    final creada = json['creadaEn'];
    return NotificacionModel(
      id: json['id'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      cuerpo: json['cuerpo'] as String? ?? '',
      datos: datos is Map ? Map<String, dynamic>.from(datos) : const {},
      creadaEn: creada is String ? DateTime.tryParse(creada) : null,
      leida: json['leida'] as bool? ?? false,
    );
  }

  DestinoNotificacion? get destino => DestinoNotificacion.desdeDatos(datos);

  NotificacionModel marcarLeida() => NotificacionModel(
        id: id,
        tipo: tipo,
        titulo: titulo,
        cuerpo: cuerpo,
        datos: datos,
        creadaEn: creadaEn,
        leida: true,
      );

  @override
  List<Object?> get props => [id, tipo, titulo, cuerpo, datos, creadaEn, leida];
}
