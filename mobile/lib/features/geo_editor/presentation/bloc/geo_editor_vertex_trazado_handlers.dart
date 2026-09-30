import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/tagged_vertex.dart';
import '../../domain/services/geodesic_calculator.dart';
import 'geo_editor_bloc.dart';
import 'geo_editor_event.dart';
import 'geo_editor_state.dart';

extension GeoEditorVertexTrazadoHandlers on GeoEditorBloc {
  void onToqueEnMapaRequested(
    ToqueEnMapaRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    if (state.isClosed) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        errorMessage:
            'El polígono ya está cerrado. Para agregar nuevos puntos reinicie el levantamiento.',
      ));
      return;
    }

    final nuevoCoord = [event.longitud, event.latitud];
    final nuevoTagged = TaggedVertex(
      longitude: event.longitud,
      latitude: event.latitud,
      origen: OrigenVertice.toqueMapa,
    );

    final nuevosVertices = List<List<double>>.from(state.vertices)
      ..add(nuevoCoord);
    final nuevosTagged = List<TaggedVertex>.from(state.verticesEtiquetados)
      ..add(nuevoTagged);

    final area = GeodesicCalculator.calcularArea(nuevosVertices);
    final perimetro = GeodesicCalculator.calcularPerimetro(nuevosVertices);

    emit(state.copyWith(
      vertices: nuevosVertices,
      verticesEtiquetados: nuevosTagged,
      areaCalculadaM2: area,
      perimetroMetros: perimetro,
      status: GeoEditorStatus.tracking,
      clearError: true,
    ));
  }

  void onDeshacerVerticeRequested(
    DeshacerVerticeRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    if (state.vertices.isEmpty) return;

    final nuevosVertices = List<List<double>>.from(state.vertices)
      ..removeLast();
    final nuevosTagged = List<TaggedVertex>.from(state.verticesEtiquetados);
    if (nuevosTagged.isNotEmpty) {
      nuevosTagged.removeLast();
    }
    final area = GeodesicCalculator.calcularArea(nuevosVertices);
    final perimetro = GeodesicCalculator.calcularPerimetro(nuevosVertices);

    emit(state.copyWith(
      vertices: nuevosVertices,
      verticesEtiquetados: nuevosTagged,
      isClosed: false,
      status: GeoEditorStatus.tracking,
      areaCalculadaM2: area,
      perimetroMetros: perimetro,
      clearError: true,
    ));
  }

  void onLimpiarVerticesRequested(
    LimpiarVerticesRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    emit(state.copyWith(
      vertices: [],
      verticesEtiquetados: [],
      isClosed: false,
      areaCalculadaM2: 0.0,
      perimetroMetros: 0.0,
      status: GeoEditorStatus.tracking,
      clearError: true,
    ));
  }

  void onCerrarPoligonoRequested(
    CerrarPoligonoRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    if (state.vertices.length < 3) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        errorMessage:
            'Se requieren al menos 3 vértices distintos para cerrar el polígono.',
      ));
      return;
    }

    final ring = List<List<double>>.from(state.vertices);
    final ringTagged = List<TaggedVertex>.from(state.verticesEtiquetados);
    final p0 = ring.first;
    final pLast = ring.last;
    if (p0[0] != pLast[0] || p0[1] != pLast[1]) {
      ring.add(p0);
      if (ringTagged.isNotEmpty) {
        ringTagged.add(ringTagged.first);
      }
    }

    if (GeodesicCalculator.tieneAutoInterseccion(ring)) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        errorMessage:
            'El perímetro se cruza a sí mismo (forma de X). Ajuste los vértices o use Deshacer para trazar el contorno en orden continuo.',
      ));
      return;
    }

    final ringCCW = GeodesicCalculator.normalizarSentidoAntihorario(ring);
    List<TaggedVertex> ringTaggedCCW = ringTagged;
    if (ring.length >= 4 &&
        ringCCW.length == ring.length &&
        ringTagged.length == ring.length &&
        (ringCCW[1][0] != ring[1][0] || ringCCW[1][1] != ring[1][1])) {
      final sinCierre =
          ringTagged.sublist(0, ringTagged.length - 1).reversed.toList();
      sinCierre.add(sinCierre.first);
      ringTaggedCCW = sinCierre;
    }

    final areaFinal = GeodesicCalculator.calcularArea(ringCCW);
    final perimetroFinal = GeodesicCalculator.calcularPerimetro(ringCCW);

    emit(state.copyWith(
      vertices: ringCCW,
      verticesEtiquetados: ringTaggedCCW,
      isClosed: true,
      areaCalculadaM2: areaFinal,
      perimetroMetros: perimetroFinal,
      status: GeoEditorStatus.readyToSave,
      clearError: true,
    ));
  }
}
