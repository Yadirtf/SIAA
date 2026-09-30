import 'package:equatable/equatable.dart';

import 'justificacion_catalogos.dart';

/// Criterios de la bandeja de justificaciones (por defecto, las radicadas).
class JustificacionesFiltro extends Equatable {
  static const int limitePorDefecto = 25;

  final String? estado;
  final String? tipo;
  final String? docenteId;
  final String? desde;
  final String? hasta;
  final int pagina;
  final int limite;

  const JustificacionesFiltro({
    this.estado = JustificacionCatalogos.radicada,
    this.tipo,
    this.docenteId,
    this.desde,
    this.hasta,
    this.pagina = 1,
    this.limite = limitePorDefecto,
  });

  /// Copia el filtro; los campos anulables se pasan como funciones para
  /// poder limpiarlos (p. ej. `tipo: () => null`).
  JustificacionesFiltro copyWith({
    String? Function()? estado,
    String? Function()? tipo,
    String? Function()? docenteId,
    String? Function()? desde,
    String? Function()? hasta,
    int? pagina,
    int? limite,
  }) {
    return JustificacionesFiltro(
      estado: estado != null ? estado() : this.estado,
      tipo: tipo != null ? tipo() : this.tipo,
      docenteId: docenteId != null ? docenteId() : this.docenteId,
      desde: desde != null ? desde() : this.desde,
      hasta: hasta != null ? hasta() : this.hasta,
      pagina: pagina ?? this.pagina,
      limite: limite ?? this.limite,
    );
  }

  /// Parámetros de consulta de GET /justificaciones.
  Map<String, String> toQuery() {
    void poner(Map<String, String> q, String k, String? v) {
      if (v != null && v.isNotEmpty) q[k] = v;
    }

    final q = <String, String>{};
    poner(q, 'estado', estado);
    poner(q, 'tipo', tipo);
    poner(q, 'docenteId', docenteId);
    poner(q, 'desde', desde);
    poner(q, 'hasta', hasta);
    q['pagina'] = '$pagina';
    q['limite'] = '$limite';
    return q;
  }

  @override
  List<Object?> get props => [
    estado,
    tipo,
    docenteId,
    desde,
    hasta,
    pagina,
    limite,
  ];
}
