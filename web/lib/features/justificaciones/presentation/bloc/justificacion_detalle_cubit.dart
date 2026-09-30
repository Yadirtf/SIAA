import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/archivo_binario.dart';
import '../../../../core/network/mensaje_error.dart';
import '../../data/models/adjunto_model.dart';
import '../../data/models/justificacion_catalogos.dart';
import '../../data/models/justificacion_model.dart';
import '../../domain/justificaciones_repository.dart';

class JustificacionDetalleState extends Equatable {
  final JustificacionModel justificacion;
  final bool procesando;
  final String? error;
  final String? mensajeExito;

  /// Nombres resueltos de docente, revisor y actores del historial.
  final Map<String, String> nombres;

  const JustificacionDetalleState({
    required this.justificacion,
    this.procesando = false,
    this.error,
    this.mensajeExito,
    this.nombres = const {},
  });

  String nombreDe(String id) => nombres[id] ?? id;

  JustificacionDetalleState copyWith({
    JustificacionModel? justificacion,
    bool? procesando,
    String? error,
    String? mensajeExito,
    Map<String, String>? nombres,
  }) {
    return JustificacionDetalleState(
      justificacion: justificacion ?? this.justificacion,
      procesando: procesando ?? this.procesando,
      error: error,
      mensajeExito: mensajeExito,
      nombres: nombres ?? this.nombres,
    );
  }

  @override
  List<Object?> get props => [
    justificacion,
    procesando,
    error,
    mensajeExito,
    nombres,
  ];
}

/// Detalle de una justificación: refresco, decisión y descarga de soportes.
class JustificacionDetalleCubit extends Cubit<JustificacionDetalleState> {
  final JustificacionesRepository _repository;

  JustificacionDetalleCubit({
    required JustificacionesRepository repository,
    required JustificacionModel inicial,
    Map<String, String> nombres = const {},
  }) : _repository = repository,
       super(
         JustificacionDetalleState(justificacion: inicial, nombres: nombres),
       );

  /// Trae la versión vigente y resuelve los nombres de los participantes.
  Future<void> cargar() async {
    try {
      final j = await _repository.obtener(state.justificacion.id);
      if (isClosed) return;
      emit(state.copyWith(justificacion: j));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(error: mensajeDeError(e)));
    }
    await _resolverNombres();
  }

  /// Aplica una decisión. Devuelve true si el backend la aceptó.
  Future<bool> revisar(String estado, {String? observaciones}) async {
    final obs = observaciones?.trim();
    if (estado == JustificacionCatalogos.rechazada &&
        (obs == null || obs.length < JustificacionCatalogos.minObservaciones)) {
      emit(
        state.copyWith(
          error:
              'Para rechazar indique observaciones de al menos '
              '${JustificacionCatalogos.minObservaciones} caracteres.',
        ),
      );
      return false;
    }
    emit(state.copyWith(procesando: true));
    try {
      final j = await _repository.revisar(
        state.justificacion.id,
        estado: estado,
        observaciones: obs,
      );
      if (isClosed) return true;
      emit(
        state.copyWith(
          justificacion: j,
          procesando: false,
          mensajeExito:
              'Justificación '
              '${JustificacionCatalogos.etiquetaEstado(j.estado).toLowerCase()}.',
        ),
      );
      await _resolverNombres();
      return true;
    } catch (e) {
      if (isClosed) return false;
      var mensaje = mensajeDeError(e);
      if (e is ApiException && e.statusCode == 409) {
        mensaje = '$mensaje Se muestra el estado actual.';
      }
      emit(state.copyWith(procesando: false, error: mensaje));
      if (e is ApiException && e.statusCode == 409) await cargar();
      return false;
    }
  }

  /// Descarga un soporte; null (con error publicado) si falla.
  Future<ArchivoBinario?> descargarSoporte(AdjuntoModel adjunto) async {
    emit(state.copyWith(procesando: true));
    try {
      final archivo = await _repository.descargarSoporte(
        state.justificacion.id,
        adjunto.id,
      );
      if (!isClosed) emit(state.copyWith(procesando: false));
      return archivo;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(procesando: false, error: mensajeDeError(e)));
      }
      return null;
    }
  }

  Future<void> _resolverNombres() async {
    final j = state.justificacion;
    final ids = {
      j.docenteId,
      if (j.revisorId != null) j.revisorId!,
      ...j.historial.map((t) => t.actorId),
    }.where((id) => id.isNotEmpty && !state.nombres.containsKey(id));
    final nuevos = <String, String>{};
    for (final id in ids) {
      try {
        final nombre = await _repository.nombreUsuario(id);
        if (nombre != null && nombre.isNotEmpty) nuevos[id] = nombre;
      } catch (_) {}
    }
    if (nuevos.isEmpty || isClosed) return;
    emit(state.copyWith(nombres: {...state.nombres, ...nuevos}));
  }
}
