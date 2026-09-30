// filtro_marcajes.dart — Filtros del listado administrativo de marcajes (US-MAR-09)
import 'package:equatable/equatable.dart';

class FiltroMarcajes extends Equatable {
  static const limitePorPagina = 20;

  final String? resultado;
  final DateTime? desde;
  final DateTime? hasta;
  final int pagina;

  const FiltroMarcajes(
      {this.resultado, this.desde, this.hasta, this.pagina = 1});

  bool get tieneFiltros => resultado != null || desde != null || hasta != null;

  FiltroMarcajes copyWith({
    String? resultado,
    bool limpiarResultado = false,
    DateTime? desde,
    DateTime? hasta,
    bool limpiarFechas = false,
    int? pagina,
  }) {
    return FiltroMarcajes(
      resultado: limpiarResultado ? null : (resultado ?? this.resultado),
      desde: limpiarFechas ? null : (desde ?? this.desde),
      hasta: limpiarFechas ? null : (hasta ?? this.hasta),
      pagina: pagina ?? this.pagina,
    );
  }

  /// Parámetros de GET /marcajes; las fechas viajan en RFC 3339 (UTC).
  Map<String, dynamic> toQuery() {
    final q = <String, dynamic>{'pagina': pagina, 'limite': limitePorPagina};
    if (resultado != null) q['resultado'] = resultado;
    if (desde != null) {
      q['desde'] = DateTime(desde!.year, desde!.month, desde!.day)
          .toUtc()
          .toIso8601String();
    }
    if (hasta != null) {
      q['hasta'] = DateTime(hasta!.year, hasta!.month, hasta!.day, 23, 59, 59)
          .toUtc()
          .toIso8601String();
    }
    return q;
  }

  @override
  List<Object?> get props => [resultado, desde, hasta, pagina];
}

/// Solicitud de ajuste: anular o corregir el resultado, con motivo obligatorio.
class AjusteMarcaje extends Equatable {
  static const minMotivo = 20;

  final bool anular;
  final String? nuevoResultado;
  final String motivo;

  const AjusteMarcaje.anular(this.motivo)
      : anular = true,
        nuevoResultado = null;

  const AjusteMarcaje.corregir(String resultado, this.motivo)
      : anular = false,
        nuevoResultado = resultado;

  /// Cuerpo de PATCH /marcajes/:id (dto.AjusteMarcajeRequest).
  Map<String, dynamic> toJson() => {
        'accion': anular ? 'ANULAR' : 'AJUSTAR',
        'anulado': anular,
        if (nuevoResultado != null) 'nuevoResultado': nuevoResultado,
        'motivo': motivo.trim(),
      };

  @override
  List<Object?> get props => [anular, nuevoResultado, motivo];
}
