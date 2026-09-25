import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/tagged_vertex.dart';
import '../../domain/services/geodesic_calculator.dart';
import 'geo_editor_bloc.dart';
import 'geo_editor_event.dart';
import 'geo_editor_state.dart';

extension GeoEditorVertexEdicionHandlers on GeoEditorBloc {
  void onMoverVerticeRequested(
    MoverVerticeRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    if (event.index < 0 || event.index >= state.vertices.length) return;

    final nuevosVertices = List<List<double>>.from(state.vertices);
    nuevosVertices[event.index] = [event.nuevaLongitud, event.nuevaLatitud];

    if (state.isClosed && nuevosVertices.length >= 4) {
      if (event.index == 0) {
        nuevosVertices[nuevosVertices.length - 1] = [
          event.nuevaLongitud,
          event.nuevaLatitud
        ];
      } else if (event.index == nuevosVertices.length - 1) {
        nuevosVertices[0] = [event.nuevaLongitud, event.nuevaLatitud];
      }
    }

    final nuevosTagged = List<TaggedVertex>.from(state.verticesEtiquetados);
    if (event.index < nuevosTagged.length) {
      nuevosTagged[event.index] = nuevosTagged[event.index].copyWith(
        longitude: event.nuevaLongitud,
        latitude: event.nuevaLatitud,
      );
      if (state.isClosed && nuevosTagged.length >= 4) {
        if (event.index == 0) {
          nuevosTagged[nuevosTagged.length - 1] = nuevosTagged[0];
        } else if (event.index == nuevosVertices.length - 1) {
          nuevosTagged[0] = nuevosTagged[nuevosTagged.length - 1];
        }
      }
    }

    final area = GeodesicCalculator.calcularArea(nuevosVertices);
    final perimetro = GeodesicCalculator.calcularPerimetro(nuevosVertices);

    emit(state.copyWith(
      vertices: nuevosVertices,
      verticesEtiquetados: nuevosTagged,
      areaCalculadaM2: area,
      perimetroMetros: perimetro,
      verticeSeleccionadoIndex: event.index,
      clearError: true,
    ));
  }

  void onInsertarVerticeEnSegmentoRequested(
    InsertarVerticeEnSegmentoRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    final coord = [event.longitud, event.latitud];
    final tagged = TaggedVertex(
      longitude: event.longitud,
      latitude: event.latitud,
      origen: OrigenVertice.toqueMapa,
    );

    final nuevosVertices = List<List<double>>.from(state.vertices);
    final nuevosTagged = List<TaggedVertex>.from(state.verticesEtiquetados);

    final pos = (event.indexDespuesDe + 1).clamp(0, nuevosVertices.length);
    nuevosVertices.insert(pos, coord);
    if (pos <= nuevosTagged.length) {
      nuevosTagged.insert(pos, tagged);
    } else {
      nuevosTagged.add(tagged);
    }

    final area = GeodesicCalculator.calcularArea(nuevosVertices);
    final perimetro = GeodesicCalculator.calcularPerimetro(nuevosVertices);

    emit(state.copyWith(
      vertices: nuevosVertices,
      verticesEtiquetados: nuevosTagged,
      areaCalculadaM2: area,
      perimetroMetros: perimetro,
      verticeSeleccionadoIndex: pos,
      clearError: true,
    ));
  }

  void onEliminarVerticeRequested(
    EliminarVerticeRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    int distinctCount = state.vertices.length;
    if (state.isClosed && state.vertices.length >= 4) {
      distinctCount = state.vertices.length - 1;
    }

    if (distinctCount <= 3) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        errorMessage:
            'No se puede eliminar: el polígono requiere al menos 3 vértices distintos.',
      ));
      return;
    }

    if (event.index < 0 || event.index >= state.vertices.length) return;

    final nuevosVertices = List<List<double>>.from(state.vertices);
    final nuevosTagged = List<TaggedVertex>.from(state.verticesEtiquetados);

    nuevosVertices.removeAt(event.index);
    if (event.index < nuevosTagged.length) {
      nuevosTagged.removeAt(event.index);
    }

    if (state.isClosed && nuevosVertices.length >= 3) {
      final p0 = nuevosVertices.first;
      final pLast = nuevosVertices.last;
      if (p0[0] != pLast[0] || p0[1] != pLast[1]) {
        nuevosVertices.add(p0);
        if (nuevosTagged.isNotEmpty) {
          nuevosTagged.add(nuevosTagged.first);
        }
      }
    }

    final area = GeodesicCalculator.calcularArea(nuevosVertices);
    final perimetro = GeodesicCalculator.calcularPerimetro(nuevosVertices);

    emit(state.copyWith(
      vertices: nuevosVertices,
      verticesEtiquetados: nuevosTagged,
      areaCalculadaM2: area,
      perimetroMetros: perimetro,
      clearVerticeSeleccionado: true,
      clearError: true,
    ));
  }

  void onSeleccionarVerticeRequested(
    SeleccionarVerticeRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    if (event.index == null ||
        event.index! < 0 ||
        event.index! >= state.vertices.length) {
      emit(state.copyWith(clearVerticeSeleccionado: true));
    } else {
      emit(state.copyWith(verticeSeleccionadoIndex: event.index));
    }
  }
}
