// verificacion_complementaria_model.dart — Testigo de verificación complementaria (RF-GEO-016)
// El servidor normaliza mayúsculas y separadores; el cliente nunca conoce el valor esperado.
import 'package:equatable/equatable.dart';

class VerificacionComplementariaModel extends Equatable {
  static const metodoWifi = 'WIFI';
  static const metodoBle = 'BLE';
  static const metodoQr = 'QR';

  final String metodo; // WIFI | BLE | QR
  final String valor;

  const VerificacionComplementariaModel({
    required this.metodo,
    required this.valor,
  });

  factory VerificacionComplementariaModel.fromJson(Map<String, dynamic> json) {
    return VerificacionComplementariaModel(
      metodo: json['metodo'] as String? ?? '',
      valor: json['valor'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'metodo': metodo, 'valor': valor};

  @override
  List<Object?> get props => [metodo, valor];
}
