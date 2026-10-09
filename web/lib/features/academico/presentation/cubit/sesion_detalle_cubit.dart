import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/mensaje_error.dart';
import '../../data/models/sesion_model.dart';
import '../../domain/academico_repository.dart';

class SesionDetalleState extends Equatable {
  final bool cargando;
  final SesionModel? sesion;
  final String? error;

  const SesionDetalleState({this.cargando = true, this.sesion, this.error});

  @override
  List<Object?> get props => [cargando, sesion, error];
}

/// Detalle de una sesión (GET /sesiones/:id) con sus parámetros congelados y
/// los que ya difieren de la cascada vigente (US-PAR-03 AC-03).
class SesionDetalleCubit extends Cubit<SesionDetalleState> {
  final AcademicoRepository _repository;

  SesionDetalleCubit({required AcademicoRepository repository})
    : _repository = repository,
      super(const SesionDetalleState());

  Future<void> cargar(String sesionId) async {
    emit(const SesionDetalleState());
    try {
      final sesion = await _repository.getSesion(sesionId);
      emit(SesionDetalleState(cargando: false, sesion: sesion));
    } catch (e) {
      emit(SesionDetalleState(cargando: false, error: mensajeDeError(e)));
    }
  }
}
