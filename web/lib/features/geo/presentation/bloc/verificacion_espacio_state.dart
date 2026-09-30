import 'package:equatable/equatable.dart';

import '../../data/models/geo_models.dart';

enum EstadoVerificacion { editando, guardando, guardado }

/// Estado del diálogo de verificación complementaria (RF-GEO-016).
class VerificacionEspacioState extends Equatable {
  final EstadoVerificacion estado;

  /// Errores 422 del backend agrupados por campo (`wifiBssids`, `qrCodigo`…).
  final Map<String, List<String>> erroresCampo;

  /// Mensaje general del backend (403, 404, red…).
  final String? mensajeError;

  /// Espacio devuelto por el backend tras guardar.
  final EspacioModel? espacio;

  const VerificacionEspacioState({
    this.estado = EstadoVerificacion.editando,
    this.erroresCampo = const {},
    this.mensajeError,
    this.espacio,
  });

  bool get guardando => estado == EstadoVerificacion.guardando;

  String? errorDe(String campo) {
    final errores = erroresCampo[campo];
    return errores == null || errores.isEmpty ? null : errores.join('\n');
  }

  @override
  List<Object?> get props => [estado, erroresCampo, mensajeError, espacio];
}
