// marcaje_request_model.dart — Petición de marcaje hacia POST /marcajes y /marcajes/sync
// Cumple con US-MAR-02, US-MAR-04, US-MAR-05, US-MAR-10, US-MAR-11.
import 'package:equatable/equatable.dart';
import 'verificacion_complementaria_model.dart';

class IntegridadDeviceModel extends Equatable {
  final bool mockLocation;
  final bool rooteado;
  final bool emulador;

  /// Informativo: el servidor lo ignora y decide verificando [attestationToken].
  final bool attestationOk;
  final String? attestationToken;

  const IntegridadDeviceModel({
    this.mockLocation = false,
    this.rooteado = false,
    this.emulador = false,
    this.attestationOk = false,
    this.attestationToken,
  });

  factory IntegridadDeviceModel.fromJson(Map<String, dynamic> json) {
    return IntegridadDeviceModel(
      mockLocation: json['mockLocation'] as bool? ?? false,
      rooteado: json['rooteado'] as bool? ?? false,
      emulador: json['emulador'] as bool? ?? false,
      // Nunca se asume attestation válida al leer datos persistidos.
      attestationOk: false,
      attestationToken: json['attestationToken'] as String?,
    );
  }

  /// Devuelve una copia con el token indicado (o sin token si es null).
  IntegridadDeviceModel conToken(String? token) {
    return IntegridadDeviceModel(
      mockLocation: mockLocation,
      rooteado: rooteado,
      emulador: emulador,
      attestationOk: attestationOk,
      attestationToken: token,
    );
  }

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
  final VerificacionComplementariaModel? verificacionComplementaria;
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
    this.verificacionComplementaria,
    this.idempotencyKey,
  });

  factory MarcajeRequestModel.fromJson(Map<String, dynamic> json) {
    final integMap = json['integridad'] as Map<String, dynamic>? ?? {};
    final verifMap =
        json['verificacionComplementaria'] as Map<String, dynamic>?;
    return MarcajeRequestModel(
      sesionId: json['sesionId'] as String,
      tipo: json['tipo'] as String,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      precisionMetros: (json['precisionMetros'] as num).toDouble(),
      timestampDispositivo:
          DateTime.parse(json['timestampDispositivo'] as String),
      dispositivoId: json['dispositivoId'] as String,
      modeloDispositivo: json['modeloDispositivo'] as String? ?? '',
      soDispositivo: json['soDispositivo'] as String? ?? '',
      versionApp: json['versionApp'] as String,
      integridad: IntegridadDeviceModel.fromJson(integMap),
      verificacionComplementaria: verifMap == null
          ? null
          : VerificacionComplementariaModel.fromJson(verifMap),
      idempotencyKey: json['idempotencyKey'] as String?,
    );
  }

  /// Copia con integridad reemplazada (p. ej. token de attestation fresco al sincronizar).
  MarcajeRequestModel conIntegridad(IntegridadDeviceModel nueva) {
    return MarcajeRequestModel(
      sesionId: sesionId,
      tipo: tipo,
      latitud: latitud,
      longitud: longitud,
      precisionMetros: precisionMetros,
      timestampDispositivo: timestampDispositivo,
      dispositivoId: dispositivoId,
      modeloDispositivo: modeloDispositivo,
      soDispositivo: soDispositivo,
      versionApp: versionApp,
      integridad: nueva,
      verificacionComplementaria: verificacionComplementaria,
      idempotencyKey: idempotencyKey,
    );
  }

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
        if (verificacionComplementaria != null)
          'verificacionComplementaria': verificacionComplementaria!.toJson(),
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
        verificacionComplementaria,
        idempotencyKey,
      ];
}
