/// Solicitud de derechos de un titular en la bandeja de atención (US-LEG-02).
class SolicitudDerechoModel {
  final String id;
  final String titularNombre;
  final String titularCorreo;
  final String tipo;
  final String estado;
  final String descripcion;
  final Map<String, String> cambios;
  final List<ElementoSupresionModel> evaluacion;
  final String responsableId;
  final String respuesta;
  final DateTime? radicadaEn;
  final DateTime? venceEn;
  final bool vencida;

  const SolicitudDerechoModel({
    required this.id,
    required this.tipo,
    required this.estado,
    this.titularNombre = '',
    this.titularCorreo = '',
    this.descripcion = '',
    this.cambios = const {},
    this.evaluacion = const [],
    this.responsableId = '',
    this.respuesta = '',
    this.radicadaEn,
    this.venceEn,
    this.vencida = false,
  });

  factory SolicitudDerechoModel.fromJson(Map<String, dynamic> j) {
    final cambios = j['cambios'];
    final evaluacion = j['evaluacion'];
    return SolicitudDerechoModel(
      id: '${j['id'] ?? ''}',
      titularNombre: '${j['titularNombre'] ?? ''}',
      titularCorreo: '${j['titularCorreo'] ?? ''}',
      tipo: '${j['tipo'] ?? ''}',
      estado: '${j['estado'] ?? ''}',
      descripcion: '${j['descripcion'] ?? ''}',
      cambios: cambios is Map
          ? cambios.map((k, v) => MapEntry('$k', '$v'))
          : const {},
      evaluacion: evaluacion is List
          ? evaluacion
                .whereType<Map>()
                .map((e) => ElementoSupresionModel.fromJson(Map.from(e)))
                .toList()
          : const [],
      responsableId: '${j['responsableId'] ?? ''}',
      respuesta: '${j['respuesta'] ?? ''}',
      radicadaEn: DateTime.tryParse('${j['radicadaEn'] ?? ''}'),
      venceEn: DateTime.tryParse('${j['venceEn'] ?? ''}'),
      vencida: j['vencida'] == true,
    );
  }

  bool get abierta => estado == 'RADICADA' || estado == 'EN_TRAMITE';

  String get tipoLegible => tipo == 'SUPRESION' ? 'Supresión' : 'Rectificación';

  String get estadoLegible => switch (estado) {
    'RADICADA' => 'Radicada',
    'EN_TRAMITE' => 'En trámite',
    'ATENDIDA' => 'Atendida',
    'DENEGADA' => 'Denegada',
    _ => estado,
  };
}

/// Una categoría de datos: si se elimina o se conserva, con su fundamento (AC-03).
class ElementoSupresionModel {
  final String descripcion;
  final bool eliminable;
  final String fundamento;

  const ElementoSupresionModel({
    required this.descripcion,
    required this.eliminable,
    required this.fundamento,
  });

  factory ElementoSupresionModel.fromJson(Map<String, dynamic> j) =>
      ElementoSupresionModel(
        descripcion: '${j['descripcion'] ?? ''}',
        eliminable: j['decision'] == 'ELIMINABLE',
        fundamento: '${j['fundamento'] ?? ''}',
      );
}
