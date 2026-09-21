import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/gps_accuracy_status.dart';
import '../../domain/models/gps_reading.dart';
import '../../domain/services/geodesic_calculator.dart';
import '../../domain/services/vertex_capture_algorithm.dart';
import 'geo_editor_event.dart';
import 'geo_editor_state.dart';

typedef SaveGeometryCallback = Future<void> Function({
  required String espacioId,
  required List<List<double>> coordenadas,
  required String metodoCaptura,
  double? precisionPromedioMetros,
});

class GeoEditorBloc extends Bloc<GeoEditorEvent, GeoEditorState> {
  final VertexCaptureAlgorithm captureAlgorithm;
  final SaveGeometryCallback? onSaveGeometry;

  GeoEditorBloc({
    this.captureAlgorithm = const VertexCaptureAlgorithm(),
    this.onSaveGeometry,
  }) : super(const GeoEditorState()) {
    on<GpsPositionUpdated>(_onGpsPositionUpdated);
    on<CapturarVerticeRequested>(_onCapturarVerticeRequested);
    on<DeshacerVerticeRequested>(_onDeshacerVerticeRequested);
    on<LimpiarVerticesRequested>(_onLimpiarVerticesRequested);
    on<CerrarPoligonoRequested>(_onCerrarPoligonoRequested);
    on<GuardarGeometriaBackendRequested>(_onGuardarGeometriaBackendRequested);
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
      final nuevosVertices = List<List<double>>.from(state.vertices)..add(nuevoVertice);

      // Actualizar métricas dinámicas
      final area = GeodesicCalculator.calcularArea(nuevosVertices);
      final perimetro = GeodesicCalculator.calcularPerimetro(nuevosVertices);

      emit(state.copyWith(
        status: GeoEditorStatus.tracking,
        vertices: nuevosVertices,
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
    final area = GeodesicCalculator.calcularArea(nuevosVertices);
    final perimetro = GeodesicCalculator.calcularPerimetro(nuevosVertices);

    emit(state.copyWith(
      vertices: nuevosVertices,
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
    final p0 = ring.first;
    final pLast = ring.last;
    if (p0[0] != pLast[0] || p0[1] != pLast[1]) {
      ring.add(p0);
    }

    final areaFinal = GeodesicCalculator.calcularArea(ring);
    final perimetroFinal = GeodesicCalculator.calcularPerimetro(ring);

    emit(state.copyWith(
      vertices: ring,
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
          metodoCaptura: 'RECORRIDO_PERIMETRAL',
          precisionPromedioMetros: state.currentPosition?.accuracy,
        );
      }
      emit(state.copyWith(
        status: GeoEditorStatus.success,
        successMessage: 'Geometría del espacio guardada exitosamente.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GeoEditorStatus.error,
        errorMessage: 'Error al enviar geometría al servidor: $e',
      ));
    }
  }
}
