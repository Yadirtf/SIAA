import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/errores_campo.dart';
import '../../../../core/network/mensaje_error.dart';
import '../../data/geometria_remote_datasource.dart';
import '../../data/models/geo_models.dart';
import 'editor_geometria_state.dart';

/// Lógica del editor de polígono por escritorio (RF-GEO-002, §9.2 del SRS):
/// agrega, deshace y borra vértices, y guarda en el backend, que es la
/// autoridad topológica.
class EditorGeometriaCubit extends Cubit<EditorGeometriaState> {
  final EspacioModel espacio;
  final GeometriaRemoteDataSource _ds;

  EditorGeometriaCubit({
    required this.espacio,
    GeometriaRemoteDataSource? dataSource,
  }) : _ds = dataSource ?? GeometriaRemoteDataSource(),
       super(EditorGeometriaState(vertices: espacio.vertices));

  void agregarVertice(double longitud, double latitud) {
    emit(
      state.copyWith(
        vertices: [
          ...state.vertices,
          [longitud, latitud],
        ],
      ),
    );
  }

  void deshacer() {
    if (state.vertices.isEmpty) return;
    emit(
      state.copyWith(
        vertices: state.vertices.sublist(0, state.vertices.length - 1),
      ),
    );
  }

  void limpiar() => emit(state.copyWith(vertices: const []));

  void descartarSolapamiento() => emit(state.copyWith());

  Future<void> guardar({
    bool confirmarSolapamiento = false,
    String? motivo,
  }) async {
    if (state.vertices.length < 3) {
      emit(state.copyWith(error: 'Marque al menos 3 esquinas del aula.'));
      return;
    }
    emit(state.copyWith(guardando: true));
    try {
      final espacio = await _ds.guardar(
        espacioId: this.espacio.id,
        vertices: state.vertices,
        confirmarSolapamiento: confirmarSolapamiento,
        motivoSolapamiento: motivo,
      );
      emit(state.copyWith(guardando: false, guardado: espacio));
    } catch (e) {
      final avisos = erroresDeCampo(e)['confirmarSolapamiento'];
      if (avisos != null && avisos.isNotEmpty && !confirmarSolapamiento) {
        emit(state.copyWith(guardando: false, solapamiento: avisos.join('\n')));
        return;
      }
      emit(state.copyWith(guardando: false, error: mensajeDeError(e)));
    }
  }
}
