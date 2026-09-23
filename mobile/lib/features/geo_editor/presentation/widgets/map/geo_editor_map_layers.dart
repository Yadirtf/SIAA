import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../bloc/geo_editor_state.dart';
import 'gps_marker.dart';
import 'vertex_marker.dart';

class GeoEditorMapLayers {
  static List<Widget> buildVectorLayers(GeoEditorState state) {
    return [
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
    ];
  }

  static MarkerLayer buildMarkerLayer({
    required GeoEditorState state,
    void Function(int index)? onSelectVertex,
    void Function(int index)? onDeleteVertex,
  }) {
    return MarkerLayer(
      markers: [
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
    );
  }
}
