// marcaje_historial_model.dart — Modelo de historial de marcajes propios (US-MAR-08)
import 'package:equatable/equatable.dart';

class MarcajeHistorialItem extends Equatable {
  final String id;
  final String sesionId;
  final String tipo; // ENTRADA | SALIDA
  final String resultado; // ACEPTADO | RECHAZADO | AUSENCIA_AUTOMATICA
  final String? motivoRechazo;
  final String origen; // MOVIL_ONLINE, MOVIL_OFFLINE, MANUAL_DOCENTE, SISTEMA_AUTOMATICO
  final String asignatura;
  final String grupo;
  final String espacioCodigo;
  final DateTime timestampServidor;
  final DateTime timestampDispositivo;
  final double latitud;
  final double longitud;
  final double precisionMetros;
  final double? distanciaMetros;
  final bool anulado;

  const MarcajeHistorialItem({
    required this.id,
    required this.sesionId,
    required this.tipo,
    required this.resultado,
    this.motivoRechazo,
    required this.origen,
    required this.asignatura,
    required this.grupo,
    required this.espacioCodigo,
    required this.timestampServidor,
    required this.timestampDispositivo,
    this.latitud = 0.0,
    this.longitud = 0.0,
    this.precisionMetros = 0.0,
    this.distanciaMetros,
    this.anulado = false,
  });

  bool get esAceptado => resultado == 'ACEPTADO';
  bool get esRechazado => resultado == 'RECHAZADO';
  bool get esAusencia => resultado == 'AUSENCIA_AUTOMATICA';

  factory MarcajeHistorialItem.fromJson(Map<String, dynamic> json) {
    final evidencia = json['evidencia'] as Map<String, dynamic>? ?? {};
    final ubicacion = evidencia['ubicacion'] as Map<String, dynamic>? ?? {};
    final coords = ubicacion['coordinates'] as List<dynamic>? ?? [0.0, 0.0];

    return MarcajeHistorialItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      sesionId: json['sesionId'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'ENTRADA',
      resultado: json['resultado'] as String? ?? 'RECHAZADO',
      motivoRechazo: json['motivoRechazo'] as String?,
      origen: json['origen'] as String? ?? 'MOVIL_ONLINE',
      asignatura: json['asignatura'] as String? ?? 'Clase',
      grupo: json['grupo'] as String? ?? 'G1',
      espacioCodigo: json['espacioCodigo'] as String? ?? 'Aula',
      timestampServidor: DateTime.tryParse(json['timestampServidor'] as String? ?? '') ?? DateTime.now(),
      timestampDispositivo: DateTime.tryParse(evidencia['timestampDispositivo'] as String? ?? '') ?? DateTime.now(),
      longitud: coords.isNotEmpty ? (coords[0] as num).toDouble() : 0.0,
      latitud: coords.length > 1 ? (coords[1] as num).toDouble() : 0.0,
      precisionMetros: (evidencia['precision'] as num?)?.toDouble() ?? 0.0,
      distanciaMetros: (evidencia['distanciaAlPoligono'] as num?)?.toDouble(),
      anulado: json['anulado'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sesionId,
        tipo,
        resultado,
        motivoRechazo,
        origen,
        asignatura,
        grupo,
        espacioCodigo,
        timestampServidor,
        timestampDispositivo,
        latitud,
        longitud,
        precisionMetros,
        distanciaMetros,
        anulado,
      ];
}

class HistorialPaginadoModel extends Equatable {
  final List<MarcajeHistorialItem> items;
  final int total;
  final int pagina;
  final int limite;

  const HistorialPaginadoModel({
    required this.items,
    required this.total,
    required this.pagina,
    required this.limite,
  });

  factory HistorialPaginadoModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['marcajes'] as List<dynamic>? ?? [];
    final items = rawList
        .map((e) => MarcajeHistorialItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return HistorialPaginadoModel(
      items: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      pagina: (json['pagina'] as num?)?.toInt() ?? 1,
      limite: (json['limite'] as num?)?.toInt() ?? 20,
    );
  }

  @override
  List<Object?> get props => [items, total, pagina, limite];
}
