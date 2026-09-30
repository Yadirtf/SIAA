// item_sync_resultado_model.dart — Resultado individual de POST /marcajes/sync (US-MAR-11)
// Espejo de ItemSyncResultado del backend (usecase/marcaje/sync.go).
import 'package:equatable/equatable.dart';
import 'marcaje_result_model.dart';

class ItemSyncResultadoModel extends Equatable {
  final String sesionId;
  final String tipo;
  final bool exitoso;
  final String? resultado;
  final String? motivoRechazo;
  final String mensaje;
  final String? marcajeId;
  final bool requiereRevision;

  /// Fallo del servidor al procesar el item (reintentable).
  final String? error;

  const ItemSyncResultadoModel({
    required this.sesionId,
    required this.tipo,
    required this.exitoso,
    this.resultado,
    this.motivoRechazo,
    this.mensaje = '',
    this.marcajeId,
    this.requiereRevision = false,
    this.error,
  });

  /// El item falló en el servidor y debe reintentarse.
  bool get esErrorReintentable =>
      (error != null && error!.isNotEmpty) ||
      resultado == null ||
      resultado!.isEmpty;

  factory ItemSyncResultadoModel.fromJson(Map<String, dynamic> json) {
    String? noVacio(Object? v) => (v is String && v.isNotEmpty) ? v : null;
    return ItemSyncResultadoModel(
      sesionId: json['sesionId'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      exitoso: json['exitoso'] as bool? ?? false,
      resultado: noVacio(json['resultado']),
      motivoRechazo: noVacio(json['motivoRechazo']),
      mensaje: json['mensaje'] as String? ?? '',
      marcajeId: noVacio(json['marcajeId']),
      requiereRevision: json['requiereRevision'] as bool? ?? false,
      error: noVacio(json['error']),
    );
  }

  /// Convierte el resultado evaluado al modelo que usa la UI (diálogo de rechazo, etc.).
  MarcajeResultModel aResultado() {
    return MarcajeResultModel(
      marcajeId: marcajeId,
      resultado: resultado ?? 'RECHAZADO',
      motivoRechazo: motivoRechazo,
      mensaje: mensaje,
      permiteReintento: false,
      puedeJustificar: !exitoso,
    );
  }

  @override
  List<Object?> get props => [
        sesionId,
        tipo,
        exitoso,
        resultado,
        motivoRechazo,
        mensaje,
        marcajeId,
        requiereRevision,
        error,
      ];
}
