import 'package:equatable/equatable.dart';

/// Cambio de estado del historial de una justificación.
class TransicionModel extends Equatable {
  final String estado;
  final String actorId;
  final String? observaciones;
  final DateTime? en;

  const TransicionModel({
    required this.estado,
    required this.actorId,
    this.observaciones,
    this.en,
  });

  factory TransicionModel.fromJson(Map<String, dynamic> json) {
    final obs = json['observaciones']?.toString();
    return TransicionModel(
      estado: json['estado']?.toString() ?? '',
      actorId: json['actorId']?.toString() ?? '',
      observaciones: obs == null || obs.isEmpty ? null : obs,
      en: DateTime.tryParse(json['en']?.toString() ?? '')?.toLocal(),
    );
  }

  @override
  List<Object?> get props => [estado, actorId, observaciones, en];
}
