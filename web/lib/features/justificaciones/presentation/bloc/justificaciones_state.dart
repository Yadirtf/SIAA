import 'package:equatable/equatable.dart';

import '../../../../core/models/pagina.dart';
import '../../data/models/justificacion_model.dart';
import '../../data/models/justificaciones_filtro.dart';

enum JustificacionesStatus { inicial, cargando, cargado, error }

class JustificacionesState extends Equatable {
  final JustificacionesStatus status;
  final JustificacionesFiltro filtro;
  final Pagina<JustificacionModel>? pagina;
  final String? error;

  /// Nombres de docentes resueltos por id (ausente = mostrar el id).
  final Map<String, String> nombres;

  const JustificacionesState({
    this.status = JustificacionesStatus.inicial,
    this.filtro = const JustificacionesFiltro(),
    this.pagina,
    this.error,
    this.nombres = const {},
  });

  List<JustificacionModel> get justificaciones => pagina?.items ?? const [];

  String nombreDe(String id) => nombres[id] ?? id;

  JustificacionesState copyWith({
    JustificacionesStatus? status,
    JustificacionesFiltro? filtro,
    Pagina<JustificacionModel>? pagina,
    String? error,
    Map<String, String>? nombres,
  }) {
    return JustificacionesState(
      status: status ?? this.status,
      filtro: filtro ?? this.filtro,
      pagina: pagina ?? this.pagina,
      error: error,
      nombres: nombres ?? this.nombres,
    );
  }

  @override
  List<Object?> get props => [status, filtro, pagina, error, nombres];
}
