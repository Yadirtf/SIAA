// offline_marcaje_item.dart — Representación de un intento de marcaje en cola local (US-MAR-11)
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'marcaje_request_model.dart';
import 'marcaje_result_model.dart';

enum EstadoSincronizacion {
  /// En cola: se enviará cuando [OfflineMarcajeItem.proximoIntento] haya pasado.
  pendiente,

  /// Evaluado y aceptado por el servidor.
  sincronizado,

  /// Evaluado por el servidor pero no aceptado (final; el docente puede justificar).
  rechazado,

  /// Agotó los reintentos automáticos o el servidor rechazó el lote (4xx); reintento manual.
  fallido,
}

class OfflineMarcajeItem extends Equatable {
  /// Versión del formato persistido; los items sin ella provienen del formato anterior.
  static const versionFormato = 2;

  final String localId;
  final MarcajeRequestModel request;
  final DateTime creadoEn;
  final EstadoSincronizacion estado;
  final String? errorMensaje;
  final MarcajeResultModel? resultadoServidor;
  final int intentos;
  final DateTime? proximoIntento;
  final bool exigirAttestation;
  final bool requiereRevision;
  final DateTime? sincronizadoEn;

  const OfflineMarcajeItem({
    required this.localId,
    required this.request,
    required this.creadoEn,
    this.estado = EstadoSincronizacion.pendiente,
    this.errorMensaje,
    this.resultadoServidor,
    this.intentos = 0,
    this.proximoIntento,
    this.exigirAttestation = false,
    this.requiereRevision = false,
    this.sincronizadoEn,
  });

  /// Listo para enviarse en este instante.
  bool esSincronizable(DateTime ahora) =>
      estado == EstadoSincronizacion.pendiente &&
      (proximoIntento == null || !proximoIntento!.isAfter(ahora));

  OfflineMarcajeItem copyWith({
    EstadoSincronizacion? estado,
    String? errorMensaje,
    bool limpiarError = false,
    MarcajeResultModel? resultadoServidor,
    int? intentos,
    DateTime? proximoIntento,
    bool limpiarProximoIntento = false,
    bool? requiereRevision,
    DateTime? sincronizadoEn,
  }) {
    return OfflineMarcajeItem(
      localId: localId,
      request: request,
      creadoEn: creadoEn,
      estado: estado ?? this.estado,
      errorMensaje: limpiarError ? null : (errorMensaje ?? this.errorMensaje),
      resultadoServidor: resultadoServidor ?? this.resultadoServidor,
      intentos: intentos ?? this.intentos,
      proximoIntento: limpiarProximoIntento
          ? null
          : (proximoIntento ?? this.proximoIntento),
      exigirAttestation: exigirAttestation,
      requiereRevision: requiereRevision ?? this.requiereRevision,
      sincronizadoEn: sincronizadoEn ?? this.sincronizadoEn,
    );
  }

  Map<String, dynamic> toMap() => {
        'version': versionFormato,
        'localId': localId,
        // El token de attestation caduca: nunca se persiste, se pide al sincronizar.
        'request':
            request.conIntegridad(request.integridad.conToken(null)).toJson(),
        'creadoEn': creadoEn.toIso8601String(),
        'estado': estado.name,
        'errorMensaje': errorMensaje,
        'resultadoServidor': resultadoServidor?.toJson(),
        'intentos': intentos,
        'proximoIntento': proximoIntento?.toIso8601String(),
        'exigirAttestation': exigirAttestation,
        'requiereRevision': requiereRevision,
        'sincronizadoEn': sincronizadoEn?.toIso8601String(),
      };

  factory OfflineMarcajeItem.fromMap(Map<String, dynamic> map) {
    final request =
        MarcajeRequestModel.fromJson(map['request'] as Map<String, dynamic>);

    MarcajeResultModel? res;
    if (map['resultadoServidor'] != null) {
      res = MarcajeResultModel.fromJson(
          map['resultadoServidor'] as Map<String, dynamic>);
    }

    final estadoStr = map['estado'] as String? ?? 'pendiente';
    var estado = EstadoSincronizacion.values.firstWhere(
      (e) => e.name == estadoStr,
      orElse: () => EstadoSincronizacion.pendiente,
    );
    final esLegado = map['version'] == null;
    if (esLegado) estado = _migrarEstadoLegado(estado, res);

    return OfflineMarcajeItem(
      localId: map['localId'] as String,
      request: request,
      creadoEn: DateTime.parse(map['creadoEn'] as String),
      estado: estado,
      errorMensaje: map['errorMensaje'] as String?,
      resultadoServidor: res,
      intentos: esLegado ? 0 : (map['intentos'] as num?)?.toInt() ?? 0,
      proximoIntento: esLegado ? null : _fecha(map['proximoIntento']),
      exigirAttestation: map['exigirAttestation'] as bool? ?? false,
      requiereRevision: map['requiereRevision'] as bool? ?? false,
      sincronizadoEn: _fecha(map['sincronizadoEn']),
    );
  }

  /// Formato anterior: `fallido` era definitivo por error de red → vuelve a la cola;
  /// `sincronizado` sin aceptación era en realidad un rechazo del servidor.
  static EstadoSincronizacion _migrarEstadoLegado(
    EstadoSincronizacion estado,
    MarcajeResultModel? res,
  ) {
    if (estado == EstadoSincronizacion.fallido) {
      return EstadoSincronizacion.pendiente;
    }
    if (estado == EstadoSincronizacion.sincronizado &&
        res != null &&
        !res.esAceptado) {
      return EstadoSincronizacion.rechazado;
    }
    return estado;
  }

  static DateTime? _fecha(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  String toJsonString() => jsonEncode(toMap());

  factory OfflineMarcajeItem.fromJsonString(String str) =>
      OfflineMarcajeItem.fromMap(jsonDecode(str) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        localId,
        request,
        creadoEn,
        estado,
        errorMensaje,
        resultadoServidor,
        intentos,
        proximoIntento,
        exigirAttestation,
        requiereRevision,
        sincronizadoEn,
      ];
}
