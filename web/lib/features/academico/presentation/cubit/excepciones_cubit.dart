import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/mensaje_error.dart';
import '../../data/excepciones_remote_datasource.dart';
import '../../data/generacion_sesiones_remote_datasource.dart';

/// Estado de la última operación sobre el calendario de excepciones.
class ExcepcionesState extends Equatable {
  final bool enviando;
  final String? mensaje;
  final String? error;

  /// Presente tras eliminar una excepción que liberó sesiones recuperables.
  final FechasLiberadas? liberadas;

  const ExcepcionesState({
    this.enviando = false,
    this.mensaje,
    this.error,
    this.liberadas,
  });

  @override
  List<Object?> get props => [enviando, mensaje, error, liberadas?.mensaje];
}

/// Crea y elimina excepciones (US-ACA-04) y, a pedido, regenera las sesiones de
/// las fechas liberadas (AC-04: nunca automáticamente).
class ExcepcionesCubit extends Cubit<ExcepcionesState> {
  final ExcepcionesRemoteDataSource _ds;
  final GeneracionSesionesRemoteDataSource _generacion;

  ExcepcionesCubit({
    ExcepcionesRemoteDataSource? dataSource,
    GeneracionSesionesRemoteDataSource? generacion,
  }) : _ds = dataSource ?? ExcepcionesRemoteDataSource(),
       _generacion = generacion ?? GeneracionSesionesRemoteDataSource(),
       super(const ExcepcionesState());

  Future<bool> crear({
    required String nombre,
    required String tipo,
    required String ambito,
    String? ambitoId,
    required String fechaInicio,
    required String fechaFin,
  }) async {
    emit(const ExcepcionesState(enviando: true));
    try {
      final r = await _ds.crear(
        nombre: nombre,
        tipo: tipo,
        ambito: ambito,
        ambitoId: ambitoId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
      emit(
        ExcepcionesState(
          mensaje: r.sesionesCanceladas == 0
              ? 'Excepción registrada. No había sesiones generadas en esas fechas.'
              : 'Excepción registrada. Se cancelaron ${r.sesionesCanceladas} '
                    'sesiones ya generadas; sus marcajes se conservan.',
        ),
      );
      return true;
    } catch (e) {
      emit(ExcepcionesState(error: mensajeDeError(e)));
      return false;
    }
  }

  Future<bool> eliminar(String id) async {
    emit(const ExcepcionesState(enviando: true));
    try {
      final l = await _ds.eliminar(id);
      emit(
        ExcepcionesState(
          mensaje: l.mensaje,
          liberadas: l.sesionesReactivables > 0 ? l : null,
        ),
      );
      return true;
    } catch (e) {
      emit(ExcepcionesState(error: mensajeDeError(e)));
      return false;
    }
  }

  /// Regenera los periodos afectados; recupera las sesiones canceladas por la excepción.
  Future<void> regenerar(FechasLiberadas liberadas) async {
    emit(const ExcepcionesState(enviando: true));
    try {
      var reactivadas = 0;
      for (final id in liberadas.periodoIds) {
        reactivadas += (await _generacion.generar(id)).sesionesReactivadas;
      }
      emit(ExcepcionesState(mensaje: 'Se recuperaron $reactivadas sesiones.'));
    } catch (e) {
      emit(ExcepcionesState(error: mensajeDeError(e)));
    }
  }
}
