// solicitud_derecho.dart — Caso de rectificación o supresión del titular (US-LEG-02)
import 'package:equatable/equatable.dart';

/// Una categoría de datos con lo que ocurre ante la supresión y su fundamento (AC-03).
class ElementoSupresion extends Equatable {
  final String categoria;
  final String descripcion;
  final bool eliminable;
  final String fundamento;

  const ElementoSupresion({
    required this.categoria,
    required this.descripcion,
    required this.eliminable,
    required this.fundamento,
  });

  factory ElementoSupresion.fromJson(Map<String, dynamic> j) =>
      ElementoSupresion(
        categoria: '${j['categoria'] ?? ''}',
        descripcion: '${j['descripcion'] ?? ''}',
        eliminable: j['decision'] == 'ELIMINABLE',
        fundamento: '${j['fundamento'] ?? ''}',
      );

  static List<ElementoSupresion> listaDe(Object? datos) => datos is List
      ? datos
          .whereType<Map<String, dynamic>>()
          .map(ElementoSupresion.fromJson)
          .toList()
      : const [];

  @override
  List<Object?> get props => [categoria, eliminable];
}

/// Caso radicado con su estado, responsable y plazo legal (AC-02).
class SolicitudDerecho extends Equatable {
  final String id;
  final String tipo;
  final String estado;
  final String descripcion;
  final Map<String, String> cambios;
  final List<ElementoSupresion> evaluacion;
  final String respuesta;
  final DateTime? radicadaEn;
  final DateTime? venceEn;

  const SolicitudDerecho({
    required this.id,
    required this.tipo,
    required this.estado,
    this.descripcion = '',
    this.cambios = const {},
    this.evaluacion = const [],
    this.respuesta = '',
    this.radicadaEn,
    this.venceEn,
  });

  factory SolicitudDerecho.fromJson(Map<String, dynamic> j) {
    final cambios = j['cambios'];
    return SolicitudDerecho(
      id: '${j['id'] ?? ''}',
      tipo: '${j['tipo'] ?? ''}',
      estado: '${j['estado'] ?? ''}',
      descripcion: '${j['descripcion'] ?? ''}',
      cambios: cambios is Map
          ? cambios.map((k, v) => MapEntry('$k', '$v'))
          : const {},
      evaluacion: ElementoSupresion.listaDe(j['evaluacion']),
      respuesta: '${j['respuesta'] ?? ''}',
      radicadaEn: DateTime.tryParse('${j['radicadaEn'] ?? ''}')?.toLocal(),
      venceEn: DateTime.tryParse('${j['venceEn'] ?? ''}')?.toLocal(),
    );
  }

  bool get abierta => estado == 'RADICADA' || estado == 'EN_TRAMITE';

  String get tipoLegible =>
      tipo == 'SUPRESION' ? 'Supresión de datos' : 'Rectificación de datos';

  String get estadoLegible => switch (estado) {
        'RADICADA' => 'Radicada',
        'EN_TRAMITE' => 'En trámite',
        'ATENDIDA' => 'Atendida',
        'DENEGADA' => 'Denegada',
        _ => estado,
      };

  @override
  List<Object?> get props => [id, estado, respuesta];
}
