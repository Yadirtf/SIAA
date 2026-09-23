import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/gps_accuracy_status.dart';
import '../../domain/models/gps_reading.dart';
import '../../domain/models/tagged_vertex.dart';
import '../../domain/services/geodesic_calculator.dart';
import '../../domain/services/vertex_capture_algorithm.dart';
import 'geo_editor_bloc.dart';
import 'geo_editor_event.dart';
import 'geo_editor_state.dart';

extension GeoEditorGpsHandlers on GeoEditorBloc {
  void onCambiarModoCapturaRequested(
    CambiarModoCapturaRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    emit(state.copyWith(
      modoCaptura: event.nuevoModo,
      clearError: true,
    ));
  }

  void onGpsPositionUpdated(
    GpsPositionUpdated event,
    Emitter<GeoEditorState> emit,
  ) {
    final status = GpsAccuracyStatusX.fromAccuracy(event.reading.accuracy);
    emit(state.copyWith(
      currentPosition: event.reading,
      accuracyStatus: status,
      status: state.status == GeoEditorStatus.initial ? GeoEditorStatus.tracking : state.status,
    ));
  }

  void onCapturarVerticeRequested(
    CapturarVerticeRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    if (!state.canCapture && event.lecturasManuales == null) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        errorMessage: 'No se puede capturar el punto: la precisión del GPS es insuficiente.',
      ));
      return;
    }

    emit(state.copyWith(status: GeoEditorStatus.capturing, clearError: true));

    try {
      final List<GpsReading> lecturasParaProcesar;
      if (event.lecturasManuales != null && event.lecturasManuales!.isNotEmpty) {
        lecturasParaProcesar = event.lecturasManuales!;
      } else if (state.currentPosition != null) {
        lecturasParaProcesar = List.filled(
          captureAlgorithm.muestrasRequeridas,
          state.currentPosition!,
        );
      } else {
        throw PrecisionInsuficienteException(
          message: 'Sin señal de GPS disponible.',
          umbralMetros: captureAlgorithm.umbralPrecisionMetros,
          totalMuestras: 0,
        );
      }

      final resultado = captureAlgorithm.processReadings(lecturasParaProcesar);

      final nuevoVertice = [resultado.longitude, resultado.latitude];
      final nuevoTagged = TaggedVertex(
        longitude: resultado.longitude,
        latitude: resultado.latitude,
        origen: OrigenVertice.gps,
        precision: resultado.accuracy,
      );

      final nuevosVertices = List<List<double>>.from(state.vertices)..add(nuevoVertice);
      final nuevosTagged = List<TaggedVertex>.from(state.verticesEtiquetados)..add(nuevoTagged);

      final area = GeodesicCalculator.calcularArea(nuevosVertices);
      final perimetro = GeodesicCalculator.calcularPerimetro(nuevosVertices);

      emit(state.copyWith(
        status: GeoEditorStatus.tracking,
        vertices: nuevosVertices,
        verticesEtiquetados: nuevosTagged,
        areaCalculadaM2: area,
        perimetroMetros: perimetro,
        clearError: true,
      ));
    } on PrecisionInsuficienteException catch (e) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        errorMessage: 'Error al capturar vértice: $e',
      ));
    }
  }
}
