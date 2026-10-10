// derechos_cubit.dart — Copia de datos, rectificación y supresión del titular (US-LEG-02)
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../data/derechos_remote_datasource.dart';
import 'derechos_state.dart';

/// Guarda el archivo en el dispositivo; devuelve false si el usuario cancela.
typedef GuardarArchivo = Future<bool> Function(String nombre, Uint8List bytes);

class DerechosCubit extends Cubit<DerechosState> {
  final DerechosRemoteDataSource _remote;
  final GuardarArchivo _guardar;

  DerechosCubit({
    required GuardarArchivo guardar,
    DerechosRemoteDataSource? remote,
  })  : _remote = remote ?? DerechosRemoteDataSource(),
        _guardar = guardar,
        super(const DerechosState());

  /// Carga el canal con sus plazos, las solicitudes y la evaluación de supresión.
  Future<void> cargar() async {
    emit(state.copyWith(cargando: true, limpiarAvisos: true));
    try {
      final canal = await _remote.canal();
      final solicitudes = await _remote.misSolicitudes();
      final evaluacion = await _remote.evaluarSupresion();
      emit(state.copyWith(
        cargando: false,
        canal: canal,
        solicitudes: solicitudes,
        evaluacion: evaluacion,
      ));
    } catch (e) {
      emit(state.copyWith(
        cargando: false,
        error: mensajeDeError(e,
            porDefecto: 'No fue posible consultar sus solicitudes.'),
      ));
    }
  }

  /// Descarga la copia de los datos personales y la guarda como archivo (AC-01).
  Future<void> descargarCopia() async {
    if (state.enviando) return;
    emit(state.copyWith(enviando: true, limpiarAvisos: true));
    try {
      final bytes = await _remote.descargarMisDatos();
      final guardado = await _guardar('mis-datos-siaa.json', bytes);
      emit(state.copyWith(
        enviando: false,
        mensaje: guardado
            ? 'Copia de sus datos guardada (mis-datos-siaa.json).'
            : 'Descarga cancelada.',
      ));
    } catch (e) {
      emit(state.copyWith(
        enviando: false,
        error: mensajeDeError(e,
            porDefecto: 'No fue posible descargar la copia de sus datos.'),
      ));
    }
  }

  /// Radica una rectificación o una supresión (AC-02, AC-03). Devuelve true si quedó radicada.
  Future<bool> radicar({
    required String tipo,
    required String descripcion,
    Map<String, String> cambios = const {},
  }) async {
    if (state.enviando) return false;
    emit(state.copyWith(enviando: true, limpiarAvisos: true));
    try {
      final nueva = await _remote.radicar(
          tipo: tipo, descripcion: descripcion, cambios: cambios);
      emit(state.copyWith(
        enviando: false,
        solicitudes: [nueva, ...state.solicitudes],
        mensaje: 'Solicitud radicada. Le responderemos dentro del plazo legal.',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        enviando: false,
        error: mensajeDeError(e,
            porDefecto: 'No fue posible radicar la solicitud.'),
      ));
      return false;
    }
  }
}
