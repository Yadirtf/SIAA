import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/geometria_historial_item.dart';
import '../../domain/services/vertex_capture_algorithm.dart';
import 'geo_editor_event.dart';
import 'geo_editor_gps_handlers.dart';
import 'geo_editor_persistence_handlers.dart';
import 'geo_editor_state.dart';
import 'geo_editor_vertex_edicion_handlers.dart';
import 'geo_editor_vertex_trazado_handlers.dart';

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
    // Modo de captura y telemetría GPS
    on<CambiarModoCapturaRequested>(onCambiarModoCapturaRequested);
    on<GpsPositionUpdated>(onGpsPositionUpdated);
    on<CapturarVerticeRequested>(onCapturarVerticeRequested);

    // Trazado y cierre de polígonos
    on<ToqueEnMapaRequested>(onToqueEnMapaRequested);
    on<DeshacerVerticeRequested>(onDeshacerVerticeRequested);
    on<LimpiarVerticesRequested>(onLimpiarVerticesRequested);
    on<CerrarPoligonoRequested>(onCerrarPoligonoRequested);

    // Edición fina de vértices
    on<MoverVerticeRequested>(onMoverVerticeRequested);
    on<InsertarVerticeEnSegmentoRequested>(onInsertarVerticeEnSegmentoRequested);
    on<EliminarVerticeRequested>(onEliminarVerticeRequested);
    on<SeleccionarVerticeRequested>(onSeleccionarVerticeRequested);

    // Persistencia e historial
    on<GuardarGeometriaBackendRequested>(onGuardarGeometriaBackendRequested);
    on<CargarGeometriaExistenteRequested>(onCargarGeometriaExistenteRequested);
    on<CargarVersionesHistoricasRequested>(onCargarVersionesHistoricasRequested);
    on<SeleccionarVersionPreviewRequested>(onSeleccionarVersionPreviewRequested);
  }
}
