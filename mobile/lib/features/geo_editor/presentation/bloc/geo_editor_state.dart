import 'package:equatable/equatable.dart';
import '../../domain/models/gps_accuracy_status.dart';
import '../../domain/models/gps_reading.dart';

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
  final GpsReading? currentPosition;
  final GpsAccuracyStatus accuracyStatus;
  final List<List<double>> vertices; // Lista de [longitud, latitud] ADR-04
  final bool isClosed;
  final double areaCalculadaM2;
  final double perimetroMetros;
  final String? errorMessage;
  final String? successMessage;

  const GeoEditorState({
    this.status = GeoEditorStatus.initial,
    this.currentPosition,
    this.accuracyStatus = GpsAccuracyStatus.searching,
    this.vertices = const [],
    this.isClosed = false,
    this.areaCalculadaM2 = 0.0,
    this.perimetroMetros = 0.0,
    this.errorMessage,
    this.successMessage,
  });

  /// AC-04: El botón de captura solo está habilitado si la precisión es óptima o aceptable.
  bool get canCapture =>
      status != GeoEditorStatus.capturing &&
      status != GeoEditorStatus.saving &&
      !isClosed &&
      accuracyStatus.canCapture;

  /// AC-05: El botón de deshacer está habilitado si hay al menos 1 vértice.
  bool get canUndo => vertices.isNotEmpty && status != GeoEditorStatus.saving;

  /// AC-06: Se puede cerrar si hay al menos 3 vértices distintos.
  bool get canClose => vertices.length >= 3 && !isClosed && status != GeoEditorStatus.saving;

  GeoEditorState copyWith({
    GeoEditorStatus? status,
    GpsReading? currentPosition,
    GpsAccuracyStatus? accuracyStatus,
    List<List<double>>? vertices,
    bool? isClosed,
    double? areaCalculadaM2,
    double? perimetroMetros,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
  }) {
    return GeoEditorState(
      status: status ?? this.status,
      currentPosition: currentPosition ?? this.currentPosition,
      accuracyStatus: accuracyStatus ?? this.accuracyStatus,
      vertices: vertices ?? this.vertices,
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
        currentPosition,
        accuracyStatus,
        vertices,
        isClosed,
        areaCalculadaM2,
        perimetroMetros,
        errorMessage,
        successMessage,
      ];
}
