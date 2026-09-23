import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/espacio_repository.dart';
import '../../domain/models/geometria_historial_item.dart';
import '../../domain/models/gps_accuracy_status.dart';
import '../../domain/models/gps_reading.dart';
import '../../domain/models/tagged_vertex.dart';
import '../../domain/services/geodesic_calculator.dart';
import '../../domain/services/vertex_capture_algorithm.dart';
import 'geo_editor_event.dart';
import 'geo_editor_state.dart';

typedef SaveGeometryCallback = Future<void> Function({
  required String espacioId,
  required List<List<double>> coordenadas,
  required String metodoCaptura,
  double? precisionPromedioMetros,
  bool confirmarSolapamiento,
  String? motivoSolapamiento,
});

typedef FetchHistorialCallback = Future<List<GeometriaHistorialItem>> Function(String espacioId);

class GeoEditorBloc extends Bloc<GeoEditorEvent, GeoEditorState> {
  final VertexCaptureAlgorithm captureAlgorithm;
  final SaveGeometryCallback? onSaveGeometry;
  final FetchHistorialCallback? onFetchHistorial;

  GeoEditorBloc({
    this.captureAlgorithm = const VertexCaptureAlgorithm(),
    this.onSaveGeometry,
    this.onFetchHistorial,
  }) : super(const GeoEditorState()) {
    on<CambiarModoCapturaRequested>(_onCambiarModoCapturaRequested);
    on<ToqueEnMapaRequested>(_onToqueEnMapaRequested);
    on<GpsPositionUpdated>(_onGpsPositionUpdated);
    on<CapturarVerticeRequested>(_onCapturarVerticeRequested);
    on<DeshacerVerticeRequested>(_onDeshacerVerticeRequested);
    on<LimpiarVerticesRequested>(_onLimpiarVerticesRequested);
    on<CerrarPoligonoRequested>(_onCerrarPoligonoRequested);
    on<GuardarGeometriaBackendRequested>(_onGuardarGeometriaBackendRequested);
    on<MoverVerticeRequested>(_onMoverVerticeRequested);
    on<InsertarVerticeEnSegmentoRequested>(_onInsertarVerticeEnSegmentoRequested);
    on<EliminarVerticeRequested>(_onEliminarVerticeRequested);
    on<CargarGeometriaExistenteRequested>(_onCargarGeometriaExistenteRequested);
    on<CargarVersionesHistoricasRequested>(_onCargarVersionesHistoricasRequested);
    on<SeleccionarVersionPreviewRequested>(_onSeleccionarVersionPreviewRequested);
  }

  void _onCambiarModoCapturaRequested(
    CambiarModoCapturaRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    // AC-03: La alternancia entre modo recorrido y modo mapa conserva los vértices ya capturados
    emit(state.copyWith(
      modoCaptura: event.nuevoModo,
      clearError: true,
    ));
  }

  void _onToqueEnMapaRequested(
    ToqueEnMapaRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    // AC-01: Al tocar sobre el mapa se agrega un vértice en esa coordenada
    if (state.isClosed) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        errorMessage: 'El polígono ya está cerrado. Para agregar nuevos puntos reinicie el levantamiento.',
      ));
      return;
    }

    // ADR-04: coordenadas obligatorias en orden [longitud, latitud]
    final nuevoCoord = [event.longitud, event.latitud];
    final nuevoTagged = TaggedVertex(
      longitude: event.longitud,
      latitude: event.latitud,
      origen: OrigenVertice.toqueMapa,
    );

    final nuevosVertices = List<List<double>>.from(state.vertices)..add(nuevoCoord);
    final nuevosTagged = List<TaggedVertex>.from(state.verticesEtiquetados)..add(nuevoTagged);

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

  void _onGpsPositionUpdated(
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

  void _onCapturarVerticeRequested(
    CapturarVerticeRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    // AC-04: Bloquear botón si la precisión es insuficiente
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
        // En ausencia de ráfaga externa, simulamos una ráfaga con la posición actual
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

      // AC-01, AC-02, T-GEO-02.4: ejecución del algoritmo de filtrado y promedio
      final resultado = captureAlgorithm.processReadings(lecturasParaProcesar);

      // ADR-04: coordenadas obligatorias en orden [longitud, latitud]
      final nuevoVertice = [resultado.longitude, resultado.latitude];
      final nuevoTagged = TaggedVertex(
        longitude: resultado.longitude,
        latitude: resultado.latitude,
        origen: OrigenVertice.gps,
        precision: resultado.accuracy,
      );

      final nuevosVertices = List<List<double>>.from(state.vertices)..add(nuevoVertice);
      final nuevosTagged = List<TaggedVertex>.from(state.verticesEtiquetados)..add(nuevoTagged);

      // Actualizar métricas dinámicas
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

  void _onDeshacerVerticeRequested(
    DeshacerVerticeRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    // AC-05: El usuario puede deshacer el último vértice sin reiniciar el recorrido
    if (state.vertices.isEmpty) return;

    final nuevosVertices = List<List<double>>.from(state.vertices)..removeLast();
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

  void _onLimpiarVerticesRequested(
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

  void _onCerrarPoligonoRequested(
    CerrarPoligonoRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    // AC-06: Cerrar polígono con cálculo de área en pantalla antes de enviar
    if (state.vertices.length < 3) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        errorMessage: 'Se requieren al menos 3 vértices distintos para cerrar el polígono.',
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

    final areaFinal = GeodesicCalculator.calcularArea(ring);
    final perimetroFinal = GeodesicCalculator.calcularPerimetro(ring);

    emit(state.copyWith(
      vertices: ring,
      verticesEtiquetados: ringTagged,
      isClosed: true,
      areaCalculadaM2: areaFinal,
      perimetroMetros: perimetroFinal,
      status: GeoEditorStatus.readyToSave,
      clearError: true,
    ));
  }

  Future<void> _onGuardarGeometriaBackendRequested(
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

  void _onMoverVerticeRequested(
    MoverVerticeRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    if (event.index < 0 || event.index >= state.vertices.length) return;

    final nuevosVertices = List<List<double>>.from(state.vertices);
    nuevosVertices[event.index] = [event.nuevaLongitud, event.nuevaLatitud];

    // Si el polígono está cerrado y se mueve el primer o último vértice, sincronizar cierre
    if (state.isClosed && nuevosVertices.length >= 4) {
      if (event.index == 0) {
        nuevosVertices[nuevosVertices.length - 1] = [event.nuevaLongitud, event.nuevaLatitud];
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
        } else if (event.index == nuevosTagged.length - 1) {
          nuevosTagged[0] = nuevosTagged[nuevosTagged.length - 1];
        }
      }
    }

    // T-GEO-07.3: Recálculo de área en vivo durante la edición
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

  void _onInsertarVerticeEnSegmentoRequested(
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

  void _onEliminarVerticeRequested(
    EliminarVerticeRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    // US-GEO-07 AC-03: Polígono con > 3 vértices: se permite eliminar; con exactamente 3, se impide.
    int distinctCount = state.vertices.length;
    if (state.isClosed && state.vertices.length >= 4) {
      distinctCount = state.vertices.length - 1;
    }

    if (distinctCount <= 3) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        errorMessage: 'No se puede eliminar: el polígono requiere al menos 3 vértices distintos.',
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

    // Si estaba cerrado, asegurar que el anillo exterior vuelva a cerrarse
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

  void _onCargarGeometriaExistenteRequested(
    CargarGeometriaExistenteRequested event,
    Emitter<GeoEditorState> emit,
  ) {
    if (event.coordenadas.isEmpty) return;

    final vertices = List<List<double>>.from(event.coordenadas);
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
      clearError: true,
    ));
  }

  Future<void> _onCargarVersionesHistoricasRequested(
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

  void _onSeleccionarVersionPreviewRequested(
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
