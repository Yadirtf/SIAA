import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../domain/models/capa_mapa.dart';
import '../../../domain/models/tagged_vertex.dart';
import '../../bloc/geo_editor_state.dart';
import 'geo_editor_map_banners.dart';
import 'geo_editor_map_layers.dart';
import 'map_floating_controls.dart';

/// Canvas cartográfico interactivo que ensambla teselas, polígonos del geocerco,
/// vértices capturados, marcador GPS en tiempo real y controles de mapa.
class GeoEditorMapView extends StatelessWidget {
  final MapController mapController;
  final GeoEditorState state;
  final CapaMapa capaActual;
  final VoidCallback onRotarCapa;
  final VoidCallback onIniciarGps;
  final void Function(double longitud, double latitud)? onMapTap;
  final void Function(int index)? onSelectVertex;
  final void Function(int index)? onDeleteVertex;
  final void Function(int index, double nuevaLongitud, double nuevaLatitud)?
      onMoveVertex;
  final void Function(int indexDespuesDe, double longitud, double latitud)?
      onInsertVertex;

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
      return ll.LatLng(
          state.currentPosition!.latitude, state.currentPosition!.longitude);
    }
    return const ll.LatLng(
        4.6372, -74.0839); // Coordenadas de referencia (Bogotá)
  }

  void _centrarGps() {
    if (state.currentPosition != null) {
      mapController.move(
        ll.LatLng(
            state.currentPosition!.latitude, state.currentPosition!.longitude),
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

  int? _buscarSegmentoCercano(
      ll.LatLng tap, List<List<double>> vertices, double umbralMetros) {
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

  double _distanciaPuntoASegmento(
      ll.LatLng p, ll.LatLng a, ll.LatLng b, ll.Distance distance) {
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return distance.as(ll.LengthUnit.Meter, p, a);

    final t = math.max(
        0.0,
        math.min(
            1.0,
            ((p.longitude - a.longitude) * dx +
                    (p.latitude - a.latitude) * dy) /
                lenSq));
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
              if (state.verticeSeleccionadoIndex != null) {
                onMoveVertex?.call(state.verticeSeleccionadoIndex!,
                    point.longitude, point.latitude);
                return;
              }
              if (state.isClosed && state.vertices.length >= 4) {
                final seg = _buscarSegmentoCercano(point, state.vertices, 3.5);
                if (seg != null) {
                  onInsertVertex?.call(seg, point.longitude, point.latitude);
                  return;
                }
              }
              if (state.modoCaptura == ModoCapturaEditor.mapa &&
                  !state.isClosed) {
                onMapTap?.call(point.longitude, point.latitude);
              }
            },
          ),
          children: [
            TileLayer(
              key: ValueKey(capaActual),
              urlTemplate: capaActual.urlTemplate,
              userAgentPackageName: 'com.siaa.mobile',
              maxNativeZoom: capaActual.maxNativeZoom,
              maxZoom: 22.5,
            ),
            ...GeoEditorMapLayers.buildVectorLayers(state),
            GeoEditorMapLayers.buildMarkerLayer(
              state: state,
              onSelectVertex: onSelectVertex,
              onDeleteVertex: onDeleteVertex,
            ),
            RichAttributionWidget(
              attributions: [TextSourceAttribution(capaActual.atribucion)],
            ),
          ],
        ),
        GeoEditorMapBanners(
          state: state,
          onSelectVertex: onSelectVertex,
        ),
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
