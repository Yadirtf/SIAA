import 'package:equatable/equatable.dart';

/// Parámetro congelado en una sesión que ya no coincide con el valor vigente
/// de la cascada (US-PAR-03 AC-03). La sesión conserva el congelado.
class DiferenciaParametro extends Equatable {
  final String clave;
  final Object? congelado;
  final Object? actual;

  const DiferenciaParametro({required this.clave, this.congelado, this.actual});

  factory DiferenciaParametro.fromJson(Map<String, dynamic> json) =>
      DiferenciaParametro(
        clave: json['clave']?.toString() ?? '',
        congelado: json['congelado'],
        actual: json['actual'],
      );

  /// Lista desde `parametrosDiferentes` (vacía si no viene).
  static List<DiferenciaParametro> listaDesde(dynamic valor) => valor is List
      ? valor
            .whereType<Map>()
            .map((m) => DiferenciaParametro.fromJson(Map.from(m)))
            .where((d) => d.clave.isNotEmpty)
            .toList()
      : const [];

  @override
  List<Object?> get props => [clave, congelado, actual];
}
