import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../domain/models/capa_mapa.dart';
import '../../../domain/models/tagged_vertex.dart';
import '../../bloc/geo_editor_state.dart';
import 'gps_marker.dart';
import 'map_floating_controls.dart';
import 'vertex_marker.dart';

/// Canvas cartográfico interactivo que ensambla teselas, polígonos del geocerco,
/// vértices capturados, marcador GPS en tiempo real y controles de mapa.
/// US-GEO-07: Soporta selección, arrastre/desplazamiento, inserción en aristas y eliminación de vértices.
/// US-GEO-06: Previsualización de versiones históricas superpuestas.
class GeoEditorMapView extends StatelessWidget {
  final MapController mapController;
  final GeoEditorState state;
  final CapaMapa capaActual;
  final VoidCallback onRotarCapa;
  final VoidCallback onIniciarGps;
  final void Function(double longitud, double latitud)? onMapTap;
  final void Function(int index)? onSelectVertex;
  final void Function(int index)? onDeleteVertex;
  final void Function(int index, double nuevaLongitud, double nuevaLatitud)? onMoveVertex;
  final void Function(int indexDespuesDe, double longitud, double latitud)? onInsertVertex;

  const GeoEditorMapView({
    super.key,
    required this.mapController,
    required this.state,
    required this.capaActual,
    required this.onRotarCapa,
    required this.onIniciarGps,
    this.onMapTap,
    this.onSelectVertex,
    this.onDeleteVertex,
    this.onMoveVertex,
    this.onInsertVertex,
  });

  ll.LatLng get _initialCenter {
    if (state.vertices.isNotEmpty) {
      return ll.LatLng(state.vertices.first[1], state.vertices.first[0]);
    }
    if (state.currentPosition != null) {
      return ll.LatLng(state.currentPosition!.latitude, state.currentPosition!.longitude);
    }
    return const ll.LatLng(4.6372, -74.0839); // Coordenadas de referencia (Bogotá)
  }

  void _centrarGps() {
    if (state.currentPosition != null) {
      mapController.move(
        ll.LatLng(state.currentPosition!.latitude, state.currentPosition!.longitude),
        19.5,
      );
    } else {
      onIniciarGps();
    }
  }

  void _centrarPoligono() {
    if (state.vertices.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(
      state.vertices.map((v) => ll.LatLng(v[1], v[0])).toList(),
    );
    mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
    );
  }

  void _zoomIn() {
    final currentZoom = mapController.camera.zoom;
    if (currentZoom < 22.5) {
      mapController.move(
        mapController.camera.center,
        (currentZoom + 1).clamp(3.0, 22.5),
      );
    }
  }

  void _zoomOut() {
    final currentZoom = mapController.camera.zoom;
    if (currentZoom > 3.0) {
      mapController.move(
        mapController.camera.center,
        (currentZoom - 1).clamp(3.0, 22.5),
      );
    }
  }

  /// Calcula si el punto de toque está próximo a alguna arista del polígono para insertar vértice (US-GEO-07 AC-02).
  int? _buscarSegmentoCercano(ll.LatLng tap, List<List<double>> vertices, double umbralMetros) {
    if (vertices.length < 2) return null;
    int? mejorSegmento;
    double menorDistancia = double.infinity;
    const distanceCalc = ll.Distance();

    final limite = state.isClosed ? vertices.length - 1 : vertices.length - 1;
    for (int i = 0; i < limite; i++) {
      final pA = ll.LatLng(vertices[i][1], vertices[i][0]);
      final pB = ll.LatLng(vertices[i + 1][1], vertices[i + 1][0]);

      final d = _distanciaPuntoASegmento(tap, pA, pB, distanceCalc);
      if (d < menorDistancia && d <= umbralMetros) {
        menorDistancia = d;
        mejorSegmento = i;
      }
    }
    return mejorSegmento;
  }

  double _distanciaPuntoASegmento(ll.LatLng p, ll.LatLng a, ll.LatLng b, ll.Distance distance) {
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return distance.as(ll.LengthUnit.Meter, p, a);

    final t = math.max(0.0, math.min(1.0, ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) / lenSq));
    final proj = ll.LatLng(a.latitude + t * dy, a.longitude + t * dx);
    return distance.as(ll.LengthUnit.Meter, p, proj);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: 18.5,
            minZoom: 3.0,
            maxZoom: 22.5,
            onTap: (tapPosition, point) {
              // 1. Si hay un vértice seleccionado, moverlo a la nueva coordenada (US-GEO-07 AC-01)
              if (state.verticeSeleccionadoIndex != null) {
                onMoveVertex?.call(state.verticeSeleccionadoIndex!, point.longitude, point.latitude);
                return;
              }

              // 2. Si el polígono YA está cerrado, permitir insertar vértice en arista cercana (US-GEO-07 AC-02)
              // Umbral prudente de 3.5 metros para evitar toques accidentales sobre aristas
              if (state.isClosed && state.vertices.length >= 4) {
                final seg = _buscarSegmentoCercano(point, state.vertices, 3.5);
                if (seg != null) {
                  onInsertVertex?.call(seg, point.longitude, point.latitude);
                  return;
                }
              }

              // 3. Captura secuencial por toque si está en modo mapa y trazando el contorno
              if (state.modoCaptura == ModoCapturaEditor.mapa && !state.isClosed) {
                onMapTap?.call(point.longitude, point.latitude);
              }
            },
          ),
          children: [
            // Capa de Teselas (Tiles) con overscaling automático
            TileLayer(
              key: ValueKey(capaActual),
              urlTemplate: capaActual.urlTemplate,
              userAgentPackageName: 'com.siaa.mobile',
              maxNativeZoom: capaActual.maxNativeZoom,
              maxZoom: 22.5,
            ),

            // US-GEO-06 AC-04: Capa de superposición de versión histórica si está activa
            if (state.versionPreview != null && state.versionPreview!.coordenadas.length >= 3)
              PolygonLayer<Object>(
                polygons: [
                  Polygon(
                    points: state.versionPreview!.coordenadas.map((v) => ll.LatLng(v[1], v[0])).toList(),
                    color: Colors.purpleAccent.withOpacity(0.25),
                    borderColor: Colors.purpleAccent,
                    borderStrokeWidth: 2.5,
                  ),
                ],
              ),

            // Capa de Polígono del geocerco actual
            if (state.vertices.length >= 3)
              PolygonLayer<Object>(
                polygons: [
                  Polygon(
                    points: state.vertices.map((v) => ll.LatLng(v[1], v[0])).toList(),
                    color: state.isClosed
                        ? Colors.cyanAccent.withOpacity(0.30)
                        : Colors.amberAccent.withOpacity(0.20),
                    borderColor: state.isClosed ? Colors.cyanAccent : Colors.amberAccent,
                    borderStrokeWidth: 2.5,
                  ),
                ],
              ),

            // Línea perimetral mientras se dibuja
            if (state.vertices.length >= 2 && !state.isClosed)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: state.vertices.map((v) => ll.LatLng(v[1], v[0])).toList(),
                    strokeWidth: 2.5,
                    color: Colors.amberAccent,
                  ),
                ],
              ),

            // Marcadores de Vértices y GPS
            MarkerLayer(
              markers: [
                // Vértices capturados con soporte de selección, movimiento y eliminación
                for (int i = 0; i < state.vertices.length; i++)
                  if (!state.isClosed || i < state.vertices.length - 1)
                    Marker(
                      point: ll.LatLng(state.vertices[i][1], state.vertices[i][0]),
                      width: 36,
                      height: 36,
                      child: VertexMarker(
                        index: i + 1,
                        vertex: state.verticesEtiquetados.length > i
                            ? state.verticesEtiquetados[i]
                            : null,
                        isSelected: state.verticeSeleccionadoIndex == i,
                        onTap: () => onSelectVertex?.call(i),
                        onLongPress: () => onDeleteVertex?.call(i),
                      ),
                    ),

                // Ubicación GPS real del usuario en vivo
                if (state.currentPosition != null)
                  Marker(
                    point: ll.LatLng(
                      state.currentPosition!.latitude,
                      state.currentPosition!.longitude,
                    ),
                    width: 40,
                    height: 40,
                    child: GpsMarker(accuracy: state.accuracyStatus),
                  ),
              ],
            ),

            // Atribución oficial de capas
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(capaActual.atribucion),
              ],
            ),
          ],
        ),

        // ─── Banner Informativo de Modo Edición Activa (US-GEO-07) ───────
        if (state.verticeSeleccionadoIndex != null)
          Positioned(
            top: 12,
            left: 16,
            right: 80,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vértice #${state.verticeSeleccionadoIndex! + 1} [Lat: ${state.vertices[state.verticeSeleccionadoIndex!][1].toStringAsFixed(6)}, Lon: ${state.vertices[state.verticeSeleccionadoIndex!][0].toStringAsFixed(6)}]: toque el mapa para moverlo.',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onSelectVertex?.call(-1),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ─── Banner de Previsualización de Versión Histórica (US-GEO-06) ──
        if (state.versionPreview != null)
          Positioned(
            top: state.verticeSeleccionadoIndex != null ? 64 : 12,
            left: 16,
            right: 80,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.purple.shade900.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.history_toggle_off_rounded, color: Colors.purpleAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Superposición v${state.versionPreview!.version} (${state.versionPreview!.areaMetrosCuadrados.toStringAsFixed(1)} m²)',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ─── Controles Flotantes sobre el Mapa ───────────────────────────
        Positioned(
          top: 12,
          right: 12,
          child: MapFloatingControls(
            capaActual: capaActual,
            hasGpsPosition: state.currentPosition != null,
            hasVertices: state.vertices.isNotEmpty,
            onRotarCapa: onRotarCapa,
            onCentrarGps: _centrarGps,
            onCentrarPoligono: _centrarPoligono,
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
          ),
        ),
      ],
    );
  }
}
