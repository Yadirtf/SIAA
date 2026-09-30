// marcaje_historial_model.dart — Marcaje del historial propio y del listado administrativo
// (US-MAR-08, US-MAR-09). El backend acompaña cada marcaje con nombres legibles
// (usuarioNombre, asignaturaNombre, grupoNumero, espacioCodigo); nunca se muestran ids.
import 'package:equatable/equatable.dart';

import 'resultado_marcaje.dart';

export 'resultado_marcaje.dart';

class MarcajeHistorialItem extends Equatable {
  final String id;
  final String sesionId;
  final String tipo; // ENTRADA | SALIDA
  final String resultado; // PRESENTE, TARDANZA, AUSENTE, RECHAZADO_*...
  final String? motivoRechazo;
  final String origen; // MOVIL_ONLINE, MOVIL_OFFLINE, MANUAL, AJUSTE...
  final String asignatura;
  final String grupo;
  final String espacioCodigo;
  final String usuarioNombre;
  final DateTime timestampServidor;
  final DateTime timestampDispositivo;
  final double latitud;
  final double longitud;
  final double precisionMetros;
  final double? distanciaMetros;
  final bool anulado;
  final String? motivoAjuste;

  const MarcajeHistorialItem({
    required this.id,
    required this.sesionId,
    required this.tipo,
    required this.resultado,
    this.motivoRechazo,
    required this.origen,
    required this.asignatura,
    required this.grupo,
    required this.espacioCodigo,
    this.usuarioNombre = '',
    required this.timestampServidor,
    required this.timestampDispositivo,
    this.latitud = 0.0,
    this.longitud = 0.0,
    this.precisionMetros = 0.0,
    this.distanciaMetros,
    this.anulado = false,
    this.motivoAjuste,
  });

  CategoriaResultado get categoria => categoriaDeResultado(resultado);
  bool get esAceptado =>
      categoria == CategoriaResultado.aceptado ||
      categoria == CategoriaResultado.tardanza;
  bool get esRechazado => categoria == CategoriaResultado.rechazado;
  bool get esAusencia => categoria == CategoriaResultado.ausencia;

  /// "Cálculo I · Grupo 01" (o "Sesión sin asignatura" si el backend no la resolvió).
  String get tituloSesion {
    final base = asignatura.isNotEmpty ? asignatura : 'Sesión sin asignatura';
    return grupo.isEmpty ? base : '$base · Grupo $grupo';
  }

  /// Resultados que habilitan radicar una justificación (EP-07).
  static const resultadosJustificables = {
    'AUSENTE',
    'AUSENCIA_AUTOMATICA',
    'RECHAZADO',
    'FUERA_DE_AREA',
    'FUERA_DE_TIEMPO',
    'FUERA_DE_HORARIO',
  };

  /// El backend decide la elegibilidad final (ventana hábil, duplicados).
  bool get puedeJustificarse =>
      !anulado &&
      sesionId.isNotEmpty &&
      (resultadosJustificables.contains(resultado) ||
          resultado.startsWith('RECHAZADO_'));

  factory MarcajeHistorialItem.fromJson(Map<String, dynamic> json) {
    String texto(Object? v) => v is String ? v.trim() : '';
    final geo = json['geolocalizacion'] as Map<String, dynamic>? ?? const {};
    final evidencia = json['evidencia'] as Map<String, dynamic>? ?? const {};
    final ubicacion =
        evidencia['ubicacion'] as Map<String, dynamic>? ?? const {};
    final coords =
        (geo['coordenadas'] ?? ubicacion['coordinates']) as List<dynamic>? ??
            const [];
    final servidor = DateTime.tryParse(texto(json['timestampServidor'])) ??
        DateTime.tryParse(texto(json['timestamp'])) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final motivoRechazo = texto(json['motivoRechazo']);
    final motivoAjuste = texto(json['motivoAjuste']);
    final distancia =
        (json['distanciaMetros'] ?? evidencia['distanciaAlPoligono']) as num?;

    return MarcajeHistorialItem(
      id: texto(json['id']).isNotEmpty ? texto(json['id']) : texto(json['_id']),
      sesionId: texto(json['sesionId']),
      tipo: texto(json['tipo']).isNotEmpty ? texto(json['tipo']) : 'ENTRADA',
      resultado: texto(json['resultado']),
      motivoRechazo: motivoRechazo.isEmpty ? null : motivoRechazo,
      origen: texto(json['origen']),
      asignatura: texto(json['asignaturaNombre']).isNotEmpty
          ? texto(json['asignaturaNombre'])
          : texto(json['asignatura']),
      grupo: texto(json['grupoNumero']).isNotEmpty
          ? texto(json['grupoNumero'])
          : texto(json['grupo']),
      espacioCodigo: texto(json['espacioCodigo']),
      usuarioNombre: texto(json['usuarioNombre']),
      timestampServidor: servidor,
      timestampDispositivo:
          DateTime.tryParse(texto(json['timestampDispositivo'])) ??
              DateTime.tryParse(texto(evidencia['timestampDispositivo'])) ??
              servidor,
      longitud: coords.isNotEmpty ? (coords[0] as num).toDouble() : 0.0,
      latitud: coords.length > 1 ? (coords[1] as num).toDouble() : 0.0,
      precisionMetros:
          ((geo['precisionMetros'] ?? evidencia['precision']) as num?)
                  ?.toDouble() ??
              0.0,
      distanciaMetros: distancia?.toDouble(),
      anulado: json['anulado'] as bool? ?? false,
      motivoAjuste: motivoAjuste.isEmpty ? null : motivoAjuste,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sesionId,
        tipo,
        resultado,
        motivoRechazo,
        origen,
        asignatura,
        grupo,
        espacioCodigo,
        usuarioNombre,
        timestampServidor,
        timestampDispositivo,
        latitud,
        longitud,
        precisionMetros,
        distanciaMetros,
        anulado,
        motivoAjuste,
      ];
}

/// Página de marcajes: {items, total, pagina, limite, totalPaginas}.
class HistorialPaginadoModel extends Equatable {
  final List<MarcajeHistorialItem> items;
  final int total;
  final int pagina;
  final int limite;
  final int totalPaginas;

  const HistorialPaginadoModel({
    required this.items,
    required this.total,
    required this.pagina,
    required this.limite,
    this.totalPaginas = 1,
  });

  bool get hayMas => pagina < totalPaginas;

  factory HistorialPaginadoModel.fromJson(Map<String, dynamic> json) {
    // "marcajes" se acepta por compatibilidad con respuestas antiguas.
    final rawList =
        (json['items'] ?? json['marcajes']) as List<dynamic>? ?? const [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(MarcajeHistorialItem.fromJson)
        .toList();
    final limite = (json['limite'] as num?)?.toInt() ?? 20;
    final total = (json['total'] as num?)?.toInt() ?? items.length;
    return HistorialPaginadoModel(
      items: items,
      total: total,
      pagina: (json['pagina'] as num?)?.toInt() ?? 1,
      limite: limite,
      totalPaginas: (json['totalPaginas'] as num?)?.toInt() ??
          (limite > 0 ? ((total + limite - 1) ~/ limite) : 1),
    );
  }

  @override
  List<Object?> get props => [items, total, pagina, limite, totalPaginas];
}
