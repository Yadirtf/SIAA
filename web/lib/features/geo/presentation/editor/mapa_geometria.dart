import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/theme/app_colors.dart';
import '../../domain/geometria_poligono.dart';
import 'editor_geometria_state.dart';
import 'marcador_vertice.dart';

/// Referencia inicial cuando el aula aún no tiene polígono (Bogotá).
const ll.LatLng centroPorDefecto = ll.LatLng(4.6372, -74.0839);

/// Callback con coordenadas en el orden del contrato `(longitud, latitud)`
/// (ADR-04).
typedef AlTocarPunto = void Function(double longitud, double latitud);

/// Mapa del editor: teselas satelitales u OpenStreetMap, el polígono y un
/// marcador numerado por vértice. En [ModoEditor.dibujar] cada toque agrega
/// una esquina; en [ModoEditor.editar] los vértices se arrastran, un toque
/// sobre un lado inserta un vértice y el clic derecho lo elimina (US-GEO-07).
class MapaGeometria extends StatefulWidget {
  final MapController controller;
  final List<List<double>> vertices;
  final bool satelite;
  final ModoEditor modo;
  final int? seleccionado;
  final AlTocarPunto onToque;
  final void Function(int indiceArista, double longitud, double latitud)?
  onInsertar;
  final void Function(int indice, double longitud, double latitud)? onMover;
  final ValueChanged<int?>? onSeleccionar;
  final ValueChanged<int>? onEliminar;

  const MapaGeometria({
    super.key,
    required this.controller,
    required this.vertices,
    required this.satelite,
    required this.onToque,
    this.modo = ModoEditor.dibujar,
    this.seleccionado,
    this.onInsertar,
    this.onMover,
    this.onSeleccionar,
    this.onEliminar,
  });

  @override
  State<MapaGeometria> createState() => _MapaGeometriaState();
}

class _MapaGeometriaState extends State<MapaGeometria> {
  final _clave = GlobalKey();
  bool _arrastrando = false;

  bool get _editando => widget.modo == ModoEditor.editar;

  ll.LatLng get _centroInicial {
    final v = widget.vertices;
    if (v.isEmpty) return centroPorDefecto;
    final lat = v.map((p) => p[1]).reduce((a, b) => a + b);
    final lon = v.map((p) => p[0]).reduce((a, b) => a + b);
    return ll.LatLng(lat / v.length, lon / v.length);
  }

  /// Convierte una posición global del puntero a coordenadas del mapa.
  ll.LatLng? _aLatLng(Offset global) {
    final caja = _clave.currentContext?.findRenderObject() as RenderBox?;
    if (caja == null) return null;
    return widget.controller.camera.screenOffsetToLatLng(
      caja.globalToLocal(global),
    );
  }

  void _alTocar(TapPosition pos, ll.LatLng p) {
    if (!_editando) {
      widget.onToque(p.longitude, p.latitude);
      return;
    }
    final camara = widget.controller.camera;
    final pantalla = widget.vertices.map((v) {
      final o = camara.latLngToScreenOffset(ll.LatLng(v[1], v[0]));
      return (x: o.dx, y: o.dy);
    }).toList();
    final toque = pos.relative ?? camara.latLngToScreenOffset(p);
    final arista = aristaMasCercana(pantalla, (x: toque.dx, y: toque.dy));
    if (arista == null) {
      widget.onSeleccionar?.call(null);
      return;
    }
    final a = pantalla[arista.indice];
    final b = pantalla[(arista.indice + 1) % pantalla.length];
    final punto = camara.screenOffsetToLatLng(
      Offset(a.x + arista.t * (b.x - a.x), a.y + arista.t * (b.y - a.y)),
    );
    widget.onInsertar?.call(arista.indice, punto.longitude, punto.latitude);
  }

  void _mover(int i, Offset global) {
    final p = _aLatLng(global);
    if (p != null) widget.onMover?.call(i, p.longitude, p.latitude);
  }

  @override
  Widget build(BuildContext context) {
    final puntos = widget.vertices.map((v) => ll.LatLng(v[1], v[0])).toList();
    return SizedBox.expand(
      key: _clave,
      child: FlutterMap(
        mapController: widget.controller,
        options: MapOptions(
          initialCenter: _centroInicial,
          initialZoom: widget.vertices.isEmpty ? 6 : 19,
          maxZoom: 22,
          interactionOptions: InteractionOptions(
            flags: _arrastrando ? InteractiveFlag.none : InteractiveFlag.all,
          ),
          onTap: _alTocar,
        ),
        children: [
          TileLayer(
            urlTemplate: widget.satelite
                ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            maxNativeZoom: widget.satelite ? 18 : 19,
            userAgentPackageName: 'co.edu.siaa.admin_web',
          ),
          if (puntos.length >= 3)
            PolygonLayer(
              polygons: [
                Polygon(
                  points: puntos,
                  color: AppColors.primaryAccent.withOpacity(0.25),
                  borderColor: AppColors.primaryAccent,
                  borderStrokeWidth: _editando ? 3.5 : 2.5,
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
                  width: _editando ? 30 : 26,
                  height: _editando ? 30 : 26,
                  child: MarcadorVertice(
                    numero: i + 1,
                    editable: _editando,
                    seleccionado: _editando && widget.seleccionado == i,
                    onSeleccionar: () => widget.onSeleccionar?.call(i),
                    onEliminar: () => widget.onEliminar?.call(i),
                    onArrastreInicio: (_) =>
                        setState(() => _arrastrando = true),
                    onArrastre: (g) => _mover(i, g),
                    onArrastreFin: () => setState(() => _arrastrando = false),
                  ),
                ),
            ],
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                widget.satelite
                    ? 'Tiles © Esri'
                    : '© OpenStreetMap contributors',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
