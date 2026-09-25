// offline_marcaje_item.dart — Representación de un intento de marcaje en cola local (US-MAR-11)
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'marcaje_request_model.dart';
import 'marcaje_result_model.dart';

enum EstadoSincronizacion {
  pendiente,
  sincronizado,
  fallido,
}

class OfflineMarcajeItem extends Equatable {
  final String localId;
  final MarcajeRequestModel request;
  final DateTime creadoEn;
  final EstadoSincronizacion estado;
  final String? errorMensaje;
  final MarcajeResultModel? resultadoServidor;

  const OfflineMarcajeItem({
    required this.localId,
    required this.request,
    required this.creadoEn,
    this.estado = EstadoSincronizacion.pendiente,
    this.errorMensaje,
    this.resultadoServidor,
  });

  OfflineMarcajeItem copyWith({
    EstadoSincronizacion? estado,
    String? errorMensaje,
    MarcajeResultModel? resultadoServidor,
  }) {
    return OfflineMarcajeItem(
      localId: localId,
      request: request,
      creadoEn: creadoEn,
      estado: estado ?? this.estado,
      errorMensaje: errorMensaje ?? this.errorMensaje,
      resultadoServidor: resultadoServidor ?? this.resultadoServidor,
    );
  }

  Map<String, dynamic> toMap() => {
        'localId': localId,
        'request': request.toJson(),
        'creadoEn': creadoEn.toIso8601String(),
        'estado': estado.name,
        'errorMensaje': errorMensaje,
        'resultadoServidor': resultadoServidor?.toJson(),
      };

  factory OfflineMarcajeItem.fromMap(Map<String, dynamic> map) {
    final reqMap = map['request'] as Map<String, dynamic>;
    final integMap = reqMap['integridad'] as Map<String, dynamic>? ?? {};

    final request = MarcajeRequestModel(
      sesionId: reqMap['sesionId'] as String,
      tipo: reqMap['tipo'] as String,
      latitud: (reqMap['latitud'] as num).toDouble(),
      longitud: (reqMap['longitud'] as num).toDouble(),
      precisionMetros: (reqMap['precisionMetros'] as num).toDouble(),
      timestampDispositivo: DateTime.parse(reqMap['timestampDispositivo'] as String),
      dispositivoId: reqMap['dispositivoId'] as String,
      modeloDispositivo: reqMap['modeloDispositivo'] as String? ?? '',
      soDispositivo: reqMap['soDispositivo'] as String? ?? '',
      versionApp: reqMap['versionApp'] as String,
      integridad: IntegridadDeviceModel(
        mockLocation: integMap['mockLocation'] as bool? ?? false,
        rooteado: integMap['rooteado'] as bool? ?? false,
        emulador: integMap['emulador'] as bool? ?? false,
        attestationOk: integMap['attestationOk'] as bool? ?? true,
      ),
      idempotencyKey: reqMap['idempotencyKey'] as String?,
    );

    MarcajeResultModel? res;
    if (map['resultadoServidor'] != null) {
      res = MarcajeResultModel.fromJson(map['resultadoServidor'] as Map<String, dynamic>);
    }

    final estadoStr = map['estado'] as String? ?? 'pendiente';
    final estado = EstadoSincronizacion.values.firstWhere(
      (e) => e.name == estadoStr,
      orElse: () => EstadoSincronizacion.pendiente,
    );

    return OfflineMarcajeItem(
      localId: map['localId'] as String,
      request: request,
      creadoEn: DateTime.parse(map['creadoEn'] as String),
      estado: estado,
      errorMensaje: map['errorMensaje'] as String?,
      resultadoServidor: res,
    );
  }

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
      ];
}
