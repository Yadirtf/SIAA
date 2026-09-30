import 'package:equatable/equatable.dart';
import '../../domain/models/gps_reading.dart';
import '../../domain/models/tagged_vertex.dart';

abstract class GeoEditorEvent extends Equatable {
  const GeoEditorEvent();

  @override
  List<Object?> get props => [];
}

/// Cambio de modo de captura entre recorrido perimetral (GPS) y toque en mapa (AC-03).
class CambiarModoCapturaRequested extends GeoEditorEvent {
  final ModoCapturaEditor nuevoModo;

  const CambiarModoCapturaRequested(this.nuevoModo);

  @override
  List<Object?> get props => [nuevoModo];
}

/// Captura alternativa de vértice mediante toque sobre el mapa interactivo (US-GEO-03, AC-01).
class ToqueEnMapaRequested extends GeoEditorEvent {
  final double longitud;
  final double latitud;

  const ToqueEnMapaRequested({
    required this.longitud,
    required this.latitud,
  });

  @override
  List<Object?> get props => [longitud, latitud];
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
  final List<GpsReading>?
      lecturasManuales; // Opcional, útil para testing o ráfagas directas

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
/// US-GEO-05: T-GEO-05.4 soporte para confirmación de solapamiento.
class GuardarGeometriaBackendRequested extends GeoEditorEvent {
  final String espacioId;
  final bool confirmarSolapamiento;
  final String? motivoSolapamiento;

  const GuardarGeometriaBackendRequested({
    required this.espacioId,
    this.confirmarSolapamiento = false,
    this.motivoSolapamiento,
  });

  @override
  List<Object?> get props =>
      [espacioId, confirmarSolapamiento, motivoSolapamiento];
}

/// US-GEO-07 AC-01: Arrastrar o mover un vértice existente a una nueva posición con recálculo de área.
class MoverVerticeRequested extends GeoEditorEvent {
  final int index;
  final double nuevaLongitud;
  final double nuevaLatitud;

  const MoverVerticeRequested({
    required this.index,
    required this.nuevaLongitud,
    required this.nuevaLatitud,
  });

  @override
  List<Object?> get props => [index, nuevaLongitud, nuevaLatitud];
}

/// US-GEO-07 AC-02: Tocar sobre un lado del polígono para insertar un nuevo vértice en esa arista.
class InsertarVerticeEnSegmentoRequested extends GeoEditorEvent {
  final int indexDespuesDe;
  final double longitud;
  final double latitud;

  const InsertarVerticeEnSegmentoRequested({
    required this.indexDespuesDe,
    required this.longitud,
    required this.latitud,
  });

  @override
  List<Object?> get props => [indexDespuesDe, longitud, latitud];
}

/// US-GEO-07 AC-03: Eliminar un vértice individual (restringido a más de 3 vértices).
class EliminarVerticeRequested extends GeoEditorEvent {
  final int index;

  const EliminarVerticeRequested(this.index);

  @override
  List<Object?> get props => [index];
}

/// Cargar vértices de una geometría existente para edición.
class CargarGeometriaExistenteRequested extends GeoEditorEvent {
  final List<List<double>> coordenadas;

  const CargarGeometriaExistenteRequested(this.coordenadas);

  @override
  List<Object?> get props => [coordenadas];
}

/// US-GEO-06 AC-04: Cargar historial de versiones de geometría desde el backend.
class CargarVersionesHistoricasRequested extends GeoEditorEvent {
  final String espacioId;

  const CargarVersionesHistoricasRequested(this.espacioId);

  @override
  List<Object?> get props => [espacioId];
}

/// US-GEO-06 AC-04: Seleccionar una versión histórica para superponerla sobre el mapa (o null para ocultar).
class SeleccionarVersionPreviewRequested extends GeoEditorEvent {
  final int? version;

  const SeleccionarVersionPreviewRequested(this.version);

  @override
  List<Object?> get props => [version];
}

/// Selección o deselección de un vértice para edición activa (mover/reubicar o deseleccionar con null/-1).
class SeleccionarVerticeRequested extends GeoEditorEvent {
  final int? index;

  const SeleccionarVerticeRequested(this.index);

  @override
  List<Object?> get props => [index];
}
