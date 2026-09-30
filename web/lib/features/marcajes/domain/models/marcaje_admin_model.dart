// marcaje_admin_model.dart — Modelos de marcajes para consola administrativa (US-MAR-09, US-MAR-10)
import 'package:equatable/equatable.dart';

class MarcajeAdminModel extends Equatable {
  final String id;
  final String sesionId;
  final String usuarioId;
  final String espacioId;
  final String espacioCodigo;
  final String asignatura;
  final String tipo; // ENTRADA | SALIDA
  final String resultado; // ACEPTADO | RECHAZADO | AUSENCIA_AUTOMATICA
  final String? motivoRechazo;
  final String origen; // MOVIL_ONLINE | MOVIL_OFFLINE | MANUAL_DOCENTE | SISTEMA_AUTOMATICO
  final double latitud;
  final double longitud;
  final double precisionMetros;
  final double? distanciaAlPoligono;
  final DateTime timestampServidor;
  final DateTime timestampDispositivo;
  final int desfaseSegundos;
  final String dispositivoId;
  final bool mockLocation;
  final bool rooteado;
  final bool emulador;
  final bool saltoImposible;
  final bool anulado;
  final String? motivoAjuste;
  final String? ajustadoPor;
  final DateTime? ajustadoEn;

  const MarcajeAdminModel({
    required this.id,
    required this.sesionId,
    required this.usuarioId,
    this.espacioId = '',
    this.espacioCodigo = '',
    this.asignatura = '',
    required this.tipo,
    required this.resultado,
    this.motivoRechazo,
    required this.origen,
    this.latitud = 0.0,
    this.longitud = 0.0,
    this.precisionMetros = 0.0,
    this.distanciaAlPoligono,
    required this.timestampServidor,
    required this.timestampDispositivo,
    this.desfaseSegundos = 0,
    this.dispositivoId = '',
    this.mockLocation = false,
    this.rooteado = false,
    this.emulador = false,
    this.saltoImposible = false,
    this.anulado = false,
    this.motivoAjuste,
    this.ajustadoPor,
    this.ajustadoEn,
  });

  bool get esAceptado => resultado == 'ACEPTADO';
  bool get esRechazado => resultado == 'RECHAZADO';
  bool get esAusencia => resultado == 'AUSENCIA_AUTOMATICA';
  bool get tieneAnomalia => mockLocation || rooteado || emulador || saltoImposible;

  factory MarcajeAdminModel.fromJson(Map<String, dynamic> json) {
    final evidencia = json['evidencia'] as Map<String, dynamic>? ?? {};
    final ubicacion = evidencia['ubicacion'] as Map<String, dynamic>? ?? {};
    final coords = ubicacion['coordinates'] as List<dynamic>? ?? [0.0, 0.0];
    final flags = evidencia['integridadFlags'] as Map<String, dynamic>? ?? {};
    final ajuste = json['ajuste'] as Map<String, dynamic>?;

    return MarcajeAdminModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      sesionId: json['sesionId'] as String? ?? '',
      usuarioId: json['usuarioId'] as String? ?? '',
      espacioId: json['espacioId'] as String? ?? '',
      espacioCodigo: json['espacioCodigo'] as String? ?? '',
      asignatura: json['asignatura'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'ENTRADA',
      resultado: json['resultado'] as String? ?? 'RECHAZADO',
      motivoRechazo: json['motivoRechazo'] as String?,
      origen: json['origen'] as String? ?? 'MOVIL_ONLINE',
      longitud: coords.isNotEmpty ? (coords[0] as num).toDouble() : 0.0,
      latitud: coords.length > 1 ? (coords[1] as num).toDouble() : 0.0,
      precisionMetros: (evidencia['precision'] as num?)?.toDouble() ?? 0.0,
      distanciaAlPoligono: (evidencia['distanciaAlPoligono'] as num?)?.toDouble(),
      timestampServidor: DateTime.tryParse(json['timestampServidor'] as String? ?? '') ?? DateTime.now(),
      timestampDispositivo: DateTime.tryParse(evidencia['timestampDispositivo'] as String? ?? '') ?? DateTime.now(),
      desfaseSegundos: (evidencia['desfaseRelojSegundos'] as num?)?.toInt() ?? 0,
      dispositivoId: evidencia['dispositivoId'] as String? ?? '',
      mockLocation: flags['mockLocation'] as bool? ?? false,
      rooteado: flags['rooteado'] as bool? ?? false,
      emulador: flags['emulador'] as bool? ?? false,
      saltoImposible: flags['saltoImposible'] as bool? ?? false,
      anulado: json['anulado'] as bool? ?? false,
      motivoAjuste: ajuste?['motivo'] as String?,
      ajustadoPor: ajuste?['usuarioAjustoId'] as String?,
      ajustadoEn: DateTime.tryParse(ajuste?['timestampAjuste'] as String? ?? ''),
    );
  }

  @override
  List<Object?> get props => [
        id,
        sesionId,
        usuarioId,
        tipo,
        resultado,
        origen,
        timestampServidor,
        anulado,
        mockLocation,
        saltoImposible,
      ];
}

class MarcajeAdminPageModel extends Equatable {
  final List<MarcajeAdminModel> items;
  final int total;
  final int pagina;
  final int limite;

  const MarcajeAdminPageModel({
    required this.items,
    required this.total,
    required this.pagina,
    required this.limite,
  });

  factory MarcajeAdminPageModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['marcajes'] as List<dynamic>? ?? [];
    final items = rawList
        .map((e) => MarcajeAdminModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return MarcajeAdminPageModel(
      items: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      pagina: (json['pagina'] as num?)?.toInt() ?? 1,
      limite: (json['limite'] as num?)?.toInt() ?? 20,
    );
  }

  @override
  List<Object?> get props => [items, total, pagina, limite];
}

class FiltrosMarcajeAdmin extends Equatable {
  final String? usuarioId;
  final String? sesionId;
  final String? resultado;
  final String? tipo;
  final String? origen;
  final DateTime? desde;
  final DateTime? hasta;

  const FiltrosMarcajeAdmin({
    this.usuarioId,
    this.sesionId,
    this.resultado,
    this.tipo,
    this.origen,
    this.desde,
    this.hasta,
  });

  Map<String, dynamic> toQueryParams({int pagina = 1, int limite = 20}) {
    final params = <String, dynamic>{
      'pagina': pagina,
      'limite': limite,
    };
    if (usuarioId != null && usuarioId!.isNotEmpty) params['usuarioId'] = usuarioId;
    if (sesionId != null && sesionId!.isNotEmpty) params['sesionId'] = sesionId;
    if (resultado != null && resultado!.isNotEmpty) params['resultado'] = resultado;
    if (tipo != null && tipo!.isNotEmpty) params['tipo'] = tipo;
    if (origen != null && origen!.isNotEmpty) params['origen'] = origen;
    if (desde != null) params['desde'] = desde!.toUtc().toIso8601String();
    if (hasta != null) params['hasta'] = hasta!.toUtc().toIso8601String();
    return params;
  }

  @override
  List<Object?> get props => [usuarioId, sesionId, resultado, tipo, origen, desde, hasta];
}
