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
class GeoEditorMapView extends StatelessWidget {
  final MapController mapController;
  final GeoEditorState state;
  final CapaMapa capaActual;
  final VoidCallback onRotarCapa;
  final VoidCallback onIniciarGps;
  final void Function(double longitud, double latitud)? onMapTap;

  const GeoEditorMapView({
    super.key,
    required this.mapController,
    required this.state,
    required this.capaActual,
    required this.onRotarCapa,
    required this.onIniciarGps,
    this.onMapTap,
  });

  ll.LatLng get _initialCenter {
    if (state.currentPosition != null) {
      return ll.LatLng(state.currentPosition!.latitude, state.currentPosition!.longitude);
    }
    if (state.vertices.isNotEmpty) {
      return ll.LatLng(state.vertices.first[1], state.vertices.first[0]);
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

            // Capa de Polígono del geocerco
            if (state.vertices.length >= 3)
              PolygonLayer<Object>(
                polygons: [
                  Polygon(
                    points: state.vertices.map((v) => ll.LatLng(v[1], v[0])).toList(),
                    color: state.isClosed
                        ? Colors.cyanAccent.withValues(alpha: 0.30)
                        : Colors.amberAccent.withValues(alpha: 0.20),
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
                // Vértices capturados con numeración secuencial
                for (int i = 0; i < state.vertices.length; i++)
                  Marker(
                    point: ll.LatLng(state.vertices[i][1], state.vertices[i][0]),
                    width: 32,
                    height: 32,
                    child: VertexMarker(
                      index: i + 1,
                      vertex: state.verticesEtiquetados.length > i
                          ? state.verticesEtiquetados[i]
                          : null,
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
