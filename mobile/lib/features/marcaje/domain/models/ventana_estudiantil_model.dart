// ventana_estudiantil_model.dart — Ventana de marcaje para estudiantes abierta por el docente (US-MAR-13)
import 'package:equatable/equatable.dart';

class VentanaEstudiantil extends Equatable {
  final bool abierta;
  final DateTime? abiertaEn;
  final DateTime? cierraEn;

  const VentanaEstudiantil({
    required this.abierta,
    this.abiertaEn,
    this.cierraEn,
  });

  static const cerrada = VentanaEstudiantil(abierta: false);

  /// Abierta y con hora de cierre posterior a [ahora] (hora del servidor).
  bool vigenteEn(DateTime ahora) =>
      abierta && cierraEn != null && cierraEn!.isAfter(ahora);

  factory VentanaEstudiantil.fromJson(Map<String, dynamic> json) {
    return VentanaEstudiantil(
      abierta: json['abierta'] as bool? ?? false,
      abiertaEn: DateTime.tryParse(json['abiertaEn'] as String? ?? ''),
      cierraEn: DateTime.tryParse(json['cierraEn'] as String? ?? ''),
    );
  }

  @override
  List<Object?> get props => [abierta, abiertaEn, cierraEn];
}
