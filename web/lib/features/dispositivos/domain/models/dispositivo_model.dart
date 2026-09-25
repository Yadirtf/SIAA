import 'package:equatable/equatable.dart';

/// Modelo de dominio para dispositivos confiables en Web (US-AUT-03).
class DispositivoModel extends Equatable {
  final String id;
  final String usuarioId;
  final String instalacionId;
  final String modelo;
  final String so;
  final String versionApp;
  final bool confiable;
  final bool pendienteAprobacion;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;
  final DateTime? revocadoEn;

  const DispositivoModel({
    required this.id,
    required this.usuarioId,
    required this.instalacionId,
    required this.modelo,
    required this.so,
    required this.versionApp,
    required this.confiable,
    required this.pendienteAprobacion,
    this.creadoEn,
    this.actualizadoEn,
    this.revocadoEn,
  });

  bool get esRevocado => revocadoEn != null;
  bool get esPendiente => pendienteAprobacion && !esRevocado;
  bool get esAprobado => confiable && !pendienteAprobacion && !esRevocado;

  String get estadoTexto {
    if (esRevocado) return 'Revocado';
    if (esPendiente) return 'Pendiente';
    return 'Aprobado';
  }

  factory DispositivoModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      try {
        return DateTime.parse(date.toString());
      } catch (_) {
        return null;
      }
    }

    return DispositivoModel(
      id: json['id']?.toString() ?? '',
      usuarioId: json['usuarioId']?.toString() ?? '',
      instalacionId: json['instalacionId']?.toString() ?? '',
      modelo: json['modelo']?.toString() ?? 'Dispositivo Desconocido',
      so: json['so']?.toString() ?? 'SO No Especificado',
      versionApp: json['versionApp']?.toString() ?? '1.0.0',
      confiable: json['confiable'] as bool? ?? false,
      pendienteAprobacion: json['pendienteAprobacion'] as bool? ?? false,
      creadoEn: parseDate(json['creadoEn']),
      actualizadoEn: parseDate(json['actualizadoEn']),
      revocadoEn: parseDate(json['revocadoEn']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuarioId': usuarioId,
    'instalacionId': instalacionId,
    'modelo': modelo,
    'so': so,
    'versionApp': versionApp,
    'confiable': confiable,
    'pendienteAprobacion': pendienteAprobacion,
    'creadoEn': creadoEn?.toIso8601String(),
    'actualizadoEn': actualizadoEn?.toIso8601String(),
    'revocadoEn': revocadoEn?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    usuarioId,
    instalacionId,
    modelo,
    so,
    versionApp,
    confiable,
    pendienteAprobacion,
    creadoEn,
    actualizadoEn,
    revocadoEn,
  ];
}
