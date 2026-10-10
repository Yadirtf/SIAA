import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/errores_campo.dart';
import '../../../../core/network/mensaje_error.dart';
import '../../data/geometria_remote_datasource.dart';
import '../../data/models/geo_models.dart';
import 'editor_geometria_state.dart';

/// Lógica del editor de polígono por escritorio (RF-GEO-002, RF-GEO-008):
/// dibuja un polígono nuevo o edita vértices de uno guardado (mover, insertar,
/// eliminar) y guarda en el backend, que es la autoridad topológica y de
/// versionado (US-GEO-04, US-GEO-06).
class EditorGeometriaCubit extends Cubit<EditorGeometriaState> {
  final EspacioModel espacio;
  final GeometriaRemoteDataSource _ds;

  EditorGeometriaCubit({
    required this.espacio,
    GeometriaRemoteDataSource? dataSource,
  }) : _ds = dataSource ?? GeometriaRemoteDataSource(),
       super(
         EditorGeometriaState(
           vertices: espacio.vertices,
           original: espacio.vertices,
           modo: espacio.tieneGeometria
               ? ModoEditor.editar
               : ModoEditor.dibujar,
         ),
       );

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

  /// US-GEO-07 AC-01: mueve el vértice [indice] a la nueva posición.
  void moverVertice(int indice, double longitud, double latitud) {
    if (indice < 0 || indice >= state.vertices.length) return;
    final v = [...state.vertices];
    v[indice] = [longitud, latitud];
    emit(state.copyWith(vertices: v, seleccionado: () => indice));
  }

  /// US-GEO-07 AC-02: inserta un vértice en la arista que empieza en
  /// [indiceArista] (entre ese vértice y el siguiente).
  void insertarVertice(int indiceArista, double longitud, double latitud) {
    if (indiceArista < 0 || indiceArista >= state.vertices.length) return;
    final v = [...state.vertices]
      ..insert(indiceArista + 1, [longitud, latitud]);
    emit(state.copyWith(vertices: v, seleccionado: () => indiceArista + 1));
  }

  void seleccionar(int? indice) =>
      emit(state.copyWith(seleccionado: () => indice));

  /// US-GEO-07 AC-03: elimina el vértice; con exactamente 3 se impide.
  void eliminarVertice([int? indice]) {
    final i = indice ?? state.seleccionado;
    if (i == null || i < 0 || i >= state.vertices.length) return;
    if (state.vertices.length <= 3) {
      emit(
        state.copyWith(
          error:
              'Un polígono necesita al menos 3 vértices; no se puede '
              'eliminar este.',
        ),
      );
      return;
    }
    final v = [...state.vertices]..removeAt(i);
    emit(state.copyWith(vertices: v, seleccionado: () => null));
  }

  void cambiarModo(ModoEditor modo) {
    if (modo == ModoEditor.editar && state.vertices.length < 3) return;
    emit(state.copyWith(modo: modo, seleccionado: () => null));
  }

  void deshacer() {
    if (state.vertices.isEmpty) return;
    emit(
      state.copyWith(
        vertices: state.vertices.sublist(0, state.vertices.length - 1),
        seleccionado: () => null,
      ),
    );
  }

  /// Descarta las ediciones y vuelve a la geometría guardada.
  void restaurar() => emit(
    state.copyWith(
      vertices: state.original,
      modo: state.original.length >= 3 ? ModoEditor.editar : ModoEditor.dibujar,
      seleccionado: () => null,
    ),
  );

  void limpiar() => emit(
    state.copyWith(
      vertices: const [],
      modo: ModoEditor.dibujar,
      seleccionado: () => null,
    ),
  );

  void descartarSolapamiento() => emit(state.copyWith());

  /// US-GEO-07 AC-04: guarda por PUT /espacios/:id/geometria con la versión
  /// leída como precondición; si otro usuario guardó antes, el backend
  /// responde 409 y se muestra su mensaje.
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
        versionEsperada: this.espacio.versionGeometria,
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
