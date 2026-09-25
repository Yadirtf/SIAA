// marcaje_request_model.dart — Petición de marcaje hacia POST /marcajes
// Cumple con US-MAR-02, US-MAR-04, US-MAR-05, US-MAR-10.
import 'package:equatable/equatable.dart';

class IntegridadDeviceModel extends Equatable {
  final bool mockLocation;
  final bool rooteado;
  final bool emulador;
  final bool attestationOk;
  final String? attestationToken;

  const IntegridadDeviceModel({
    this.mockLocation = false,
    this.rooteado = false,
    this.emulador = false,
    this.attestationOk = true,
    this.attestationToken,
  });

  Map<String, dynamic> toJson() => {
        'mockLocation': mockLocation,
        'rooteado': rooteado,
        'emulador': emulador,
        'attestationOk': attestationOk,
        if (attestationToken != null) 'attestationToken': attestationToken,
      };

  @override
  List<Object?> get props => [
        mockLocation,
        rooteado,
        emulador,
        attestationOk,
        attestationToken,
      ];
}

class MarcajeRequestModel extends Equatable {
  final String sesionId;
  final String tipo; // ENTRADA | SALIDA
  final double latitud;
  final double longitud;
  final double precisionMetros;
  final DateTime timestampDispositivo;
  final String dispositivoId;
  final String modeloDispositivo;
  final String soDispositivo;
  final String versionApp;
  final IntegridadDeviceModel integridad;
  final String? idempotencyKey;

  const MarcajeRequestModel({
    required this.sesionId,
    required this.tipo,
    required this.latitud,
    required this.longitud,
    required this.precisionMetros,
    required this.timestampDispositivo,
    required this.dispositivoId,
    this.modeloDispositivo = '',
    this.soDispositivo = '',
    required this.versionApp,
    this.integridad = const IntegridadDeviceModel(),
    this.idempotencyKey,
  });

  Map<String, dynamic> toJson() => {
        'sesionId': sesionId,
        'tipo': tipo,
        'latitud': latitud,
        'longitud': longitud,
        'precisionMetros': precisionMetros,
        'timestampDispositivo': timestampDispositivo.toUtc().toIso8601String(),
        'dispositivoId': dispositivoId,
        'modeloDispositivo': modeloDispositivo,
        'soDispositivo': soDispositivo,
        'versionApp': versionApp,
        'integridad': integridad.toJson(),
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      };

  @override
  List<Object?> get props => [
        sesionId,
        tipo,
        latitud,
        longitud,
        precisionMetros,
        timestampDispositivo,
        dispositivoId,
        modeloDispositivo,
        soDispositivo,
        versionApp,
        integridad,
        idempotencyKey,
      ];
}
