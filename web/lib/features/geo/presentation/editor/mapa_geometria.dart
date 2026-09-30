import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/theme/app_colors.dart';

/// Referencia inicial cuando el aula aún no tiene polígono (Bogotá).
const ll.LatLng centroPorDefecto = ll.LatLng(4.6372, -74.0839);

/// Mapa del editor: teselas satelitales u OpenStreetMap, el polígono en
/// construcción y un marcador numerado por esquina. Cada toque agrega un
/// vértice mediante [onToque] con el orden `(longitud, latitud)` (ADR-04).
class MapaGeometria extends StatelessWidget {
  final MapController controller;
  final List<List<double>> vertices;
  final bool satelite;
  final void Function(double longitud, double latitud) onToque;

  const MapaGeometria({
    super.key,
    required this.controller,
    required this.vertices,
    required this.satelite,
    required this.onToque,
  });

  List<ll.LatLng> get _puntos =>
      vertices.map((v) => ll.LatLng(v[1], v[0])).toList();

  ll.LatLng get _centroInicial {
    if (vertices.isEmpty) return centroPorDefecto;
    final lat = vertices.map((v) => v[1]).reduce((a, b) => a + b);
    final lon = vertices.map((v) => v[0]).reduce((a, b) => a + b);
    return ll.LatLng(lat / vertices.length, lon / vertices.length);
  }

  @override
  Widget build(BuildContext context) {
    final puntos = _puntos;
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: _centroInicial,
        initialZoom: vertices.isEmpty ? 6 : 19,
        maxZoom: 22,
        onTap: (_, p) => onToque(p.longitude, p.latitude),
      ),
      children: [
        TileLayer(
          urlTemplate: satelite
              ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          maxNativeZoom: satelite ? 18 : 19,
          userAgentPackageName: 'co.edu.siaa.admin_web',
        ),
        if (puntos.length >= 3)
          PolygonLayer(
            polygons: [
              Polygon(
                points: puntos,
                color: AppColors.primaryAccent.withOpacity(0.25),
                borderColor: AppColors.primaryAccent,
                borderStrokeWidth: 2.5,
              ),
            ],
          )
        else if (puntos.length == 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: puntos,
                color: AppColors.primaryAccent,
                strokeWidth: 2.5,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (var i = 0; i < puntos.length; i++)
              Marker(
                point: puntos[i],
                width: 26,
                height: 26,
                child: _Vertice(numero: i + 1),
              ),
          ],
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              satelite ? 'Tiles © Esri' : '© OpenStreetMap contributors',
            ),
          ],
        ),
      ],
    );
  }
}

class _Vertice extends StatelessWidget {
  final int numero;
  const _Vertice({required this.numero});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        '$numero',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
