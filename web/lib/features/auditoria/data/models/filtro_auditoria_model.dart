import 'package:equatable/equatable.dart';

/// Criterios de consulta de la bitácora. [accion] filtra por prefijo.
class FiltroAuditoriaModel extends Equatable {
  static const int limitePorDefecto = 50;

  final String? entidad;
  final String? entidadId;
  final String? actorId;
  final String? accion;
  final String? desde;
  final String? hasta;
  final int pagina;
  final int limite;

  const FiltroAuditoriaModel({
    this.entidad,
    this.entidadId,
    this.actorId,
    this.accion,
    this.desde,
    this.hasta,
    this.pagina = 1,
    this.limite = limitePorDefecto,
  });

  /// Copia el filtro; los campos anulables se pasan como funciones para
  /// poder limpiarlos.
  FiltroAuditoriaModel copyWith({
    String? Function()? entidad,
    String? Function()? entidadId,
    String? Function()? actorId,
    String? Function()? accion,
    String? Function()? desde,
    String? Function()? hasta,
    int? pagina,
    int? limite,
  }) {
    return FiltroAuditoriaModel(
      entidad: entidad != null ? entidad() : this.entidad,
      entidadId: entidadId != null ? entidadId() : this.entidadId,
      actorId: actorId != null ? actorId() : this.actorId,
      accion: accion != null ? accion() : this.accion,
      desde: desde != null ? desde() : this.desde,
      hasta: hasta != null ? hasta() : this.hasta,
      pagina: pagina ?? this.pagina,
      limite: limite ?? this.limite,
    );
  }

  /// Parámetros de consulta; la exportación omite la paginación.
  Map<String, String> toQuery({bool paginado = true}) {
    final q = <String, String>{};
    void poner(String k, String? v) {
      final t = v?.trim();
      if (t != null && t.isNotEmpty) q[k] = t;
    }

    poner('entidad', entidad);
    poner('entidadId', entidadId);
    poner('actorId', actorId);
    poner('accion', accion);
    poner('desde', desde);
    poner('hasta', hasta);
    if (paginado) {
      q['pagina'] = '$pagina';
      q['limite'] = '$limite';
    }
    return q;
  }

  @override
  List<Object?> get props => [
    entidad,
    entidadId,
    actorId,
    accion,
    desde,
    hasta,
    pagina,
    limite,
  ];
}
