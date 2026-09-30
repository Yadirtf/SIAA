import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/errores_campo.dart';
import '../../../../core/network/mensaje_error.dart';
import '../../data/models/geo_models.dart';
import '../../domain/geo_repository.dart';
import 'verificacion_espacio_state.dart';

/// Guarda la verificación complementaria de un espacio y expone los errores
/// de validación del backend para mostrarlos junto a cada campo.
class VerificacionEspacioCubit extends Cubit<VerificacionEspacioState> {
  final GeoRepository _repository;
  final String espacioId;

  VerificacionEspacioCubit({
    required GeoRepository repository,
    required this.espacioId,
  }) : _repository = repository,
       super(const VerificacionEspacioState());

  Future<void> guardar(VerificacionEspacioModel verificacion) async {
    if (state.guardando) return;
    emit(const VerificacionEspacioState(estado: EstadoVerificacion.guardando));
    try {
      final espacio = await _repository.actualizarVerificacion(
        espacioId,
        verificacion,
      );
      emit(
        VerificacionEspacioState(
          estado: EstadoVerificacion.guardado,
          espacio: espacio,
        ),
      );
    } catch (e) {
      final campos = erroresDeCampo(e);
      emit(
        VerificacionEspacioState(
          erroresCampo: campos,
          mensajeError: mensajeDeError(e),
        ),
      );
    }
  }

  /// Envía todo vacío: el backend elimina la verificación del espacio.
  Future<void> quitar() => guardar(VerificacionEspacioModel.vacia);
}
