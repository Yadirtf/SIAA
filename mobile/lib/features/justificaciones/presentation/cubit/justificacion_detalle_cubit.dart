// justificacion_detalle_cubit.dart — Detalle con historial y observaciones (US-JUS-03)
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/justificacion_repository.dart';
import '../../domain/models/justificacion_exception.dart';
import '../../domain/models/justificacion_model.dart';

class JustificacionDetalleState extends Equatable {
  final Justificacion justificacion;
  final bool cargando;
  final String? error;

  const JustificacionDetalleState(
    this.justificacion, {
    this.cargando = false,
    this.error,
  });

  @override
  List<Object?> get props => [justificacion, cargando, error];
}

/// Parte de la versión del listado y la actualiza con GET /justificaciones/{id}.
class JustificacionDetalleCubit extends Cubit<JustificacionDetalleState> {
  final JustificacionRepository _repository;

  JustificacionDetalleCubit(this._repository, Justificacion inicial)
      : super(JustificacionDetalleState(inicial));

  Future<void> cargar() async {
    emit(JustificacionDetalleState(state.justificacion, cargando: true));
    try {
      final j = await _repository.obtener(state.justificacion.id);
      emit(JustificacionDetalleState(j));
    } on JustificacionException catch (e) {
      emit(JustificacionDetalleState(state.justificacion, error: e.mensaje));
    }
  }
}
