import 'package:equatable/equatable.dart';
import '../../domain/models/gps_accuracy_status.dart';
import '../../domain/models/gps_reading.dart';
import '../../domain/models/tagged_vertex.dart';

enum GeoEditorStatus {
  initial,
  tracking,
  capturing,
  readyToSave,
  saving,
  success,
  error,
}

class GeoEditorState extends Equatable {
  final GeoEditorStatus status;
  final ModoCapturaEditor modoCaptura;
  final GpsReading? currentPosition;
  final GpsAccuracyStatus accuracyStatus;
  final List<List<double>> vertices; // Lista de [longitud, latitud] ADR-04
  final List<TaggedVertex> verticesEtiquetados; // Trazabilidad de origen por vértice
  final bool isClosed;
  final double areaCalculadaM2;
  final double perimetroMetros;
  final String? errorMessage;
  final String? successMessage;

  const GeoEditorState({
    this.status = GeoEditorStatus.initial,
    this.modoCaptura = ModoCapturaEditor.recorrido,
    this.currentPosition,
    this.accuracyStatus = GpsAccuracyStatus.searching,
    this.vertices = const [],
    this.verticesEtiquetados = const [],
    this.isClosed = false,
    this.areaCalculadaM2 = 0.0,
    this.perimetroMetros = 0.0,
    this.errorMessage,
    this.successMessage,
  });

  /// AC-04 (US-GEO-02): El botón de captura GPS solo está habilitado si la precisión es óptima o aceptable.
  bool get canCaptureGps =>
      modoCaptura == ModoCapturaEditor.recorrido &&
      status != GeoEditorStatus.capturing &&
      status != GeoEditorStatus.saving &&
      !isClosed &&
      accuracyStatus.canCapture;

  /// Retrocompatibilidad para captura
  bool get canCapture => canCaptureGps;

  /// AC-01 (US-GEO-03): Permite capturar por toque en mapa
  bool get canTapMap =>
      modoCaptura == ModoCapturaEditor.mapa &&
      !isClosed &&
      status != GeoEditorStatus.saving &&
      status != GeoEditorStatus.capturing;

  /// AC-05: El botón de deshacer está habilitado si hay al menos 1 vértice.
  bool get canUndo => vertices.isNotEmpty && status != GeoEditorStatus.saving;

  /// AC-06: Se puede cerrar si hay al menos 3 vértices distintos.
  bool get canClose => vertices.length >= 3 && !isClosed && status != GeoEditorStatus.saving;

  /// AC-02, AC-03: Determina el método de captura efectivo según los vértices capturados.
  /// - Exclusivamente toque: TOQUE_MAPA
  /// - Exclusivamente GPS: RECORRIDO_PERIMETRAL
  /// - Combinado: MIXTO
  String get metodoCapturaEfectivo {
    if (verticesEtiquetados.isEmpty) {
      return modoCaptura == ModoCapturaEditor.mapa ? 'TOQUE_MAPA' : 'RECORRIDO_PERIMETRAL';
    }
    final hasGps = verticesEtiquetados.any((v) => v.origen == OrigenVertice.gps);
    final hasToque = verticesEtiquetados.any((v) => v.origen == OrigenVertice.toqueMapa);
    if (hasGps && hasToque) return 'MIXTO';
    if (hasToque) return 'TOQUE_MAPA';
    return 'RECORRIDO_PERIMETRAL';
  }

  /// AC-02: En TOQUE_MAPA no se registra precisión GPS promedio (es null).
  /// En RECORRIDO_PERIMETRAL o MIXTO se promedian los vértices con precisión GPS.
  double? get precisionPromedioCalculada {
    if (metodoCapturaEfectivo == 'TOQUE_MAPA') {
      return null;
    }
    final gpsVertices = verticesEtiquetados
        .where((v) => v.origen == OrigenVertice.gps && v.precision != null)
        .toList();
    if (gpsVertices.isNotEmpty) {
      final sum = gpsVertices.fold<double>(0.0, (acc, v) => acc + (v.precision ?? 0.0));
      return sum / gpsVertices.length;
    }
    return currentPosition?.accuracy;
  }

  GeoEditorState copyWith({
    GeoEditorStatus? status,
    ModoCapturaEditor? modoCaptura,
    GpsReading? currentPosition,
    GpsAccuracyStatus? accuracyStatus,
    List<List<double>>? vertices,
    List<TaggedVertex>? verticesEtiquetados,
    bool? isClosed,
    double? areaCalculadaM2,
    double? perimetroMetros,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
  }) {
    return GeoEditorState(
      status: status ?? this.status,
      modoCaptura: modoCaptura ?? this.modoCaptura,
      currentPosition: currentPosition ?? this.currentPosition,
      accuracyStatus: accuracyStatus ?? this.accuracyStatus,
      vertices: vertices ?? this.vertices,
      verticesEtiquetados: verticesEtiquetados ?? this.verticesEtiquetados,
      isClosed: isClosed ?? this.isClosed,
      areaCalculadaM2: areaCalculadaM2 ?? this.areaCalculadaM2,
      perimetroMetros: perimetroMetros ?? this.perimetroMetros,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        modoCaptura,
        currentPosition,
        accuracyStatus,
        vertices,
        verticesEtiquetados,
        isClosed,
        areaCalculadaM2,
        perimetroMetros,
        errorMessage,
        successMessage,
      ];
}
