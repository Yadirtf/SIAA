import 'package:equatable/equatable.dart';

import '../../data/models/tablero_model.dart';

enum TableroStatus { inicial, cargando, cargado, error }

class TableroState extends Equatable {
  final TableroStatus status;
  final TableroModel? tablero;

  /// Error de la última consulta; si ya había datos se conservan en pantalla.
  final String? error;

  /// Espera hasta la siguiente actualización (base del servidor + desfase).
  final Duration? proximaActualizacion;

  const TableroState({
    this.status = TableroStatus.inicial,
    this.tablero,
    this.error,
    this.proximaActualizacion,
  });

  TableroState copyWith({
    TableroStatus? status,
    TableroModel? tablero,
    String? Function()? error,
    Duration? proximaActualizacion,
  }) => TableroState(
    status: status ?? this.status,
    tablero: tablero ?? this.tablero,
    error: error != null ? error() : this.error,
    proximaActualizacion: proximaActualizacion ?? this.proximaActualizacion,
  );

  @override
  List<Object?> get props => [status, tablero, error, proximaActualizacion];
}
