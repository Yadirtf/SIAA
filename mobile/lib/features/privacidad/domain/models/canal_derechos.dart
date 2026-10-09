// canal_derechos.dart — Canal publicado y plazos legales del titular (US-LEG-02 AC-04)
import 'package:equatable/equatable.dart';

class PlazoDerecho extends Equatable {
  final String tipo;
  final String descripcion;
  final int diasHabiles;
  final int prorroga;
  final String fundamento;

  const PlazoDerecho({
    required this.tipo,
    required this.descripcion,
    required this.diasHabiles,
    required this.prorroga,
    required this.fundamento,
  });

  factory PlazoDerecho.fromJson(Map<String, dynamic> j) => PlazoDerecho(
        tipo: '${j['tipo'] ?? ''}',
        descripcion: '${j['descripcion'] ?? ''}',
        diasHabiles: (j['diasHabiles'] as num?)?.toInt() ?? 0,
        prorroga: (j['prorrogaDiasHabiles'] as num?)?.toInt() ?? 0,
        fundamento: '${j['fundamentoLegal'] ?? ''}',
      );

  @override
  List<Object?> get props => [tipo, diasHabiles, prorroga];
}

class CanalDerechos extends Equatable {
  final String contacto;
  final String autoridad;
  final List<PlazoDerecho> plazos;

  const CanalDerechos({
    this.contacto = '',
    this.autoridad = '',
    this.plazos = const [],
  });

  factory CanalDerechos.fromJson(Map<String, dynamic> j) => CanalDerechos(
        contacto: '${j['contacto'] ?? ''}',
        autoridad: '${j['autoridad'] ?? ''}',
        plazos: (j['plazos'] is List)
            ? (j['plazos'] as List)
                .whereType<Map<String, dynamic>>()
                .map(PlazoDerecho.fromJson)
                .toList()
            : const [],
      );

  @override
  List<Object?> get props => [contacto, plazos];
}
