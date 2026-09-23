import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/espacio_repository.dart';
import '../../domain/models/tagged_vertex.dart';
import '../../domain/services/geodesic_calculator.dart';
import 'geo_editor_bloc.dart';
import 'geo_editor_event.dart';
import 'geo_editor_state.dart';

extension GeoEditorPersistenceHandlers on GeoEditorBloc {
  Future<void> onGuardarGeometriaBackendRequested(
    GuardarGeometriaBackendRequested event,
    Emitter<GeoEditorState> emit,
  ) async {
    if (!state.isClosed || state.vertices.length < 4) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        errorMessage: 'El polígono debe estar cerrado antes de enviarse al backend.',
      ));
      return;
    }

    emit(state.copyWith(status: GeoEditorStatus.saving, clearError: true));

    try {
      if (onSaveGeometry != null) {
        await onSaveGeometry!(
          espacioId: event.espacioId,
          coordenadas: state.vertices,
          metodoCaptura: state.metodoCapturaEfectivo,
          precisionPromedioMetros: state.precisionPromedioCalculada,
          confirmarSolapamiento: event.confirmarSolapamiento,
          motivoSolapamiento: event.motivoSolapamiento,
        );
      }
      emit(state.copyWith(
        status: GeoEditorStatus.success,
        successMessage: 'Geometría del espacio guardada exitosamente.',
        clearSolapamiento: true,
      ));
    } on SolapamientoAdvertenciaException catch (e) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        solapamientoAdvertencia: e.mensaje,
        solapamientoDetalles: e.detalles,
        errorMessage: e.mensaje,
      ));
    } on SolapamientoCriticoException catch (e) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        solapamientoCritico: e.mensaje,
        errorMessage: e.mensaje,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        errorMessage: 'Error al enviar geometría al servidor: $e',
      ));
    }
  }

  void onCargarGeometriaExistenteRequested(
    CargarGeometriaExistenteRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    if (event.coordenadas.isEmpty) return;

    final vertices = List<List<double>>.from(event.coordenadas);
    if (vertices.length >= 3 &&
        (vertices.first[0] != vertices.last[0] || vertices.first[1] != vertices.last[1])) {
      vertices.add([vertices.first[0], vertices.first[1]]);
    }

    final tagged = vertices.map((c) => TaggedVertex(
      longitude: c[0],
      latitude: c[1],
      origen: OrigenVertice.toqueMapa,
    )).toList();

    final isClosed = vertices.length >= 4 &&
        vertices.first[0] == vertices.last[0] &&
        vertices.first[1] == vertices.last[1];

    final area = GeodesicCalculator.calcularArea(vertices);
    final perimetro = GeodesicCalculator.calcularPerimetro(vertices);

    emit(state.copyWith(
      vertices: vertices,
      verticesEtiquetados: tagged,
      isClosed: isClosed,
      areaCalculadaM2: area,
      perimetroMetros: perimetro,
      status: isClosed ? GeoEditorStatus.readyToSave : GeoEditorStatus.tracking,
      modoCaptura: ModoCapturaEditor.mapa,
      clearVerticeSeleccionado: true,
      clearError: true,
    ));
  }

  Future<void> onCargarVersionesHistoricasRequested(
    CargarVersionesHistoricasRequested event,
    Emitter<GeoEditorState> emit,
  ) async {
    emit(state.copyWith(isLoadingHistorial: true, clearError: true));
    try {
      if (onFetchHistorial != null) {
        final versiones = await onFetchHistorial!(event.espacioId);
        emit(state.copyWith(
          versionesHistoricas: versiones,
          isLoadingHistorial: false,
        ));
      } else {
        emit(state.copyWith(isLoadingHistorial: false));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoadingHistorial: false,
        errorMessage: 'Error al consultar versiones anteriores: $e',
      ));
    }
  }

  void onSeleccionarVersionPreviewRequested(
    SeleccionarVersionPreviewRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    if (event.version == null) {
      emit(state.copyWith(clearVersionPreview: true));
      return;
    }

    final match = state.versionesHistoricas.where((v) => v.version == event.version).firstOrNull;
    if (match != null) {
      emit(state.copyWith(versionPreview: match));
    } else {
      emit(state.copyWith(clearVersionPreview: true));
    }
  }
}
