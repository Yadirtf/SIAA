import 'package:equatable/equatable.dart';
import '../../domain/models/gps_reading.dart';

abstract class GeoEditorEvent extends Equatable {
  const GeoEditorEvent();

  @override
  List<Object?> get props => [];
}

/// Actualización de la posición GPS en tiempo real para el semáforo y preview.
class GpsPositionUpdated extends GeoEditorEvent {
  final GpsReading reading;

  const GpsPositionUpdated(this.reading);

  @override
  List<Object?> get props => [reading];
}

/// Solicitud de captura de un vértice mediante el algoritmo de filtrado y promedio (AC-01, AC-02).
class CapturarVerticeRequested extends GeoEditorEvent {
  final List<GpsReading>? lecturasManuales; // Opcional, útil para testing o ráfagas directas

  const CapturarVerticeRequested({this.lecturasManuales});

  @override
  List<Object?> get props => [lecturasManuales];
}

/// AC-05: El usuario puede deshacer el último vértice capturado sin reiniciar el recorrido.
class DeshacerVerticeRequested extends GeoEditorEvent {
  const DeshacerVerticeRequested();
}

/// Reiniciar todos los vértices del polígono en edición.
class LimpiarVerticesRequested extends GeoEditorEvent {
  const LimpiarVerticesRequested();
}

/// AC-06: Cerrar polígono con cálculo de área en pantalla antes de enviar.
class CerrarPoligonoRequested extends GeoEditorEvent {
  const CerrarPoligonoRequested();
}

/// Envío del polígono cerrado al backend vía PUT /api/v1/espacios/:id/geometria.
class GuardarGeometriaBackendRequested extends GeoEditorEvent {
  final String espacioId;

  const GuardarGeometriaBackendRequested({required this.espacioId});

  @override
  List<Object?> get props => [espacioId];
}
