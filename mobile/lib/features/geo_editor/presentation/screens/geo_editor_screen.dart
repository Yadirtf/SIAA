import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/gps_accuracy_status.dart';
import '../../domain/models/gps_reading.dart';
import '../../domain/models/tagged_vertex.dart';
import '../../domain/services/gps_location_service.dart';
import '../bloc/geo_editor_bloc.dart';
import '../bloc/geo_editor_event.dart';
import '../bloc/geo_editor_state.dart';
import '../widgets/gps_traffic_light_badge.dart';

/// Pantalla interactiva de levantamiento cartográfico perimetral (US-GEO-02, US-GEO-03, US-GEO-05).
/// Implementa:
/// - RF-GEO-002: Recorrido perimetral por GPS con semáforo de precisión en vivo.
/// - RF-GEO-004: Captura por toque sobre mapa satelital / callejero (OpenStreetMap & Esri World Imagery).
/// - RN-005: Solicitud interactiva de permisos de ubicación en primer plano (while in use).
/// - US-GEO-05: Diálogos modales de advertencia de solapamiento y bloqueo duro >50%.
class GeoEditorScreen extends StatefulWidget {
  final String espacioId;
  final String espacioCodigo;
  final String espacioNombre;

  const GeoEditorScreen({
    super.key,
    required this.espacioId,
    required this.espacioCodigo,
    required this.espacioNombre,
  });

  @override
  State<GeoEditorScreen> createState() => _GeoEditorScreenState();
}

enum CapaMapa {
  googleHibrido,
  esriSatelite,
  openStreetMap,
}

class _GeoEditorScreenState extends State<GeoEditorScreen> {
  final GpsLocationService _gpsService = GpsLocationService();
  final MapController _mapController = MapController();

  EstadoPermisoUbicacion? _estadoPermiso;
  CapaMapa _capaActual = CapaMapa.googleHibrido;
  bool _mapaCentradoInicialmente = false;

  String get _urlTemplateActual {
    switch (_capaActual) {
      case CapaMapa.googleHibrido:
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case CapaMapa.esriSatelite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case CapaMapa.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  int get _maxNativeZoomActual {
    switch (_capaActual) {
      case CapaMapa.googleHibrido:
        return 20; // Cobertura satelital nativa de Google hasta nivel 20
      case CapaMapa.esriSatelite:
        return 18; // Clampeado a 18 para evitar el tile "Map data not yet available" de Esri al pedir z=19+
      case CapaMapa.openStreetMap:
        return 19;
    }
  }

  String get _nombreCapaActual {
    switch (_capaActual) {
      case CapaMapa.googleHibrido:
        return 'Google Satélite Híbrido (HD)';
      case CapaMapa.esriSatelite:
        return 'Esri Satélite (Puro)';
      case CapaMapa.openStreetMap:
        return 'OpenStreetMap (Callejero)';
    }
  }

  String get _atribucionActual {
    switch (_capaActual) {
      case CapaMapa.googleHibrido:
        return 'Imágenes © Google';
      case CapaMapa.esriSatelite:
        return 'Tiles © Esri';
      case CapaMapa.openStreetMap:
        return '© OpenStreetMap contributors';
    }
  }

  IconData get _iconoCapaActual {
    switch (_capaActual) {
      case CapaMapa.googleHibrido:
        return Icons.satellite_alt_rounded;
      case CapaMapa.esriSatelite:
        return Icons.public;
      case CapaMapa.openStreetMap:
        return Icons.map_outlined;
    }
  }

  void _rotarCapaMapa() {
    setState(() {
      switch (_capaActual) {
        case CapaMapa.googleHibrido:
          _capaActual = CapaMapa.esriSatelite;
          break;
        case CapaMapa.esriSatelite:
          _capaActual = CapaMapa.openStreetMap;
          break;
        case CapaMapa.openStreetMap:
          _capaActual = CapaMapa.googleHibrido;
          break;
      }
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Capa activa: $_nombreCapaActual'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _iniciarGps();
  }

  Future<void> _iniciarGps() async {
    final estado = await _gpsService.escucharPosicionesConPermiso(
      onReading: (reading) {
        if (!mounted) return;
        context.read<GeoEditorBloc>().add(GpsPositionUpdated(reading));

        // Al recibir la primera lectura GPS real, centrar el mapa suavemente
        if (!_mapaCentradoInicialmente) {
          _mapaCentradoInicialmente = true;
          _mapController.move(ll.LatLng(reading.latitude, reading.longitude), 18.5);
        }
      },
      onError: (err) {
        // En emuladores o entornos sin sensor el error no bloquea el modo mapa
      },
    );

    if (mounted) {
      setState(() {
        _estadoPermiso = estado;
      });
    }
  }

  @override
  void dispose() {
    _gpsService.detenerEscucha();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GeoEditorBloc, GeoEditorState>(
      listener: (context, state) {
        // US-GEO-05 AC-03: Bloqueo irremovible ante solapamiento > 50%
        if (state.solapamientoCritico != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Row(
                children: const [
                  Icon(Icons.block, color: SIAAColors.asistenciaAusente),
                  SizedBox(width: 8),
                  Text('Solapamiento Crítico (>50%)', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              content: Text(
                state.solapamientoCritico!,
                style: const TextStyle(color: SIAAColors.neutral300, fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Entendido', style: TextStyle(color: Colors.cyanAccent)),
                ),
              ],
            ),
          );
          return;
        }

        // US-GEO-05 AC-01 & AC-02: Advertencia ante solapamiento <= 50% con confirmación
        if (state.solapamientoAdvertencia != null) {
          final motivoCtrl = TextEditingController();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.amberAccent),
                  SizedBox(width: 8),
                  Text('Advertencia de Solapamiento', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.solapamientoAdvertencia!,
                    style: const TextStyle(color: SIAAColors.neutral200, fontSize: 13),
                  ),
                  if (state.solapamientoDetalles != null && state.solapamientoDetalles!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...state.solapamientoDetalles!.map(
                      (d) => Text('• $d', style: const TextStyle(color: SIAAColors.neutral400, fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Indique el motivo para confirmar el guardado (quedará auditado):',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: motivoCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Ej. Tolerancia por muro divisorio compartido',
                      hintStyle: TextStyle(color: SIAAColors.neutral500, fontSize: 12),
                      filled: true,
                      fillColor: Color(0xFF0F172A),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: SIAAColors.neutral400)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
                  onPressed: () {
                    final motivo = motivoCtrl.text.trim();
                    Navigator.of(dialogCtx).pop();
                    context.read<GeoEditorBloc>().add(
                          GuardarGeometriaBackendRequested(
                            espacioId: widget.espacioId,
                            confirmarSolapamiento: true,
                            motivoSolapamiento: motivo.isNotEmpty ? motivo : 'Confirmado por usuario en campo',
                          ),
                        );
                  },
                  child: const Text('Confirmar y Guardar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          return;
        }

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: SIAAColors.asistenciaAusente,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: SIAAColors.asistenciaPresente,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        // Centro inicial: posición GPS real, o primer vértice, o Universidad Nacional (Bogotá)
        final initialCenter = state.currentPosition != null
            ? ll.LatLng(state.currentPosition!.latitude, state.currentPosition!.longitude)
            : (state.vertices.isNotEmpty
                ? ll.LatLng(state.vertices.first[1], state.vertices.first[0])
                : const ll.LatLng(4.6372, -74.0839));

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cartografía: ${widget.espacioCodigo}', style: const TextStyle(fontSize: 16)),
                Text(
                  widget.espacioNombre,
                  style: const TextStyle(fontSize: 12, color: SIAAColors.neutral400),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reiniciar polígono',
                onPressed: state.vertices.isNotEmpty ? () => _confirmarReinicio(context) : null,
              ),
            ],
          ),
          body: Column(
            children: [
              // ─── Banner de Permisos de Ubicación (si no están concedidos) ─────
              _buildBannerPermisos(),

              // ─── Selector de modo de captura (RF-GEO-002 vs RF-GEO-004) ──────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<ModoCapturaEditor>(
                        segments: const [
                          ButtonSegment<ModoCapturaEditor>(
                            value: ModoCapturaEditor.recorrido,
                            icon: Icon(Icons.directions_walk, size: 16),
                            label: Text('GPS Recorrido'),
                          ),
                          ButtonSegment<ModoCapturaEditor>(
                            value: ModoCapturaEditor.mapa,
                            icon: Icon(Icons.touch_app, size: 16),
                            label: Text('Toque Mapa'),
                          ),
                        ],
                        selected: {state.modoCaptura},
                        onSelectionChanged: (Set<ModoCapturaEditor> newSelection) {
                          context.read<GeoEditorBloc>().add(
                                CambiarModoCapturaRequested(newSelection.first),
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Barra de estado de telemetría y método de captura ─────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (state.modoCaptura == ModoCapturaEditor.recorrido)
                      GpsTrafficLightBadge(
                        status: state.accuracyStatus,
                        accuracyMetros: state.currentPosition?.accuracy,
                      )
                    else
                      _buildModoMapaBadge(state),
                    Row(
                      children: [
                        _buildMetodoBadge(state.metodoCapturaEfectivo),
                        const SizedBox(width: 8),
                        Text(
                          '${state.vertices.length} pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: SIAAColors.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── Banner informativo en modo mapa ──────────────────────────────
              if (state.modoCaptura == ModoCapturaEditor.mapa)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  color: const Color(0xFFFEF3C7), // Amber 100
                  child: Row(
                    children: const [
                      Icon(Icons.touch_app, size: 16, color: Color(0xFFB45309)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Modo Toque en Mapa: Toque directamente sobre el mapa satelital para posicionar cada esquina del aula.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),

              // ─── MAPA INTERACTIVO REAL (OpenStreetMap / Esri World Imagery) ───
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: initialCenter,
                        initialZoom: 18.5,
                        minZoom: 3.0,
                        maxZoom: 22.5,
                        onTap: (tapPosition, point) {
                          if (state.modoCaptura == ModoCapturaEditor.mapa && !state.isClosed) {
                            context.read<GeoEditorBloc>().add(
                                  ToqueEnMapaRequested(
                                    longitud: point.longitude,
                                    latitud: point.latitude,
                                  ),
                                );
                          }
                        },
                      ),
                      children: [
                        // Capa de Teselas (Tiles): Satelital o Callejero con sobre-escalado automático (overscaling)
                        TileLayer(
                          key: ValueKey(_capaActual),
                          urlTemplate: _urlTemplateActual,
                          userAgentPackageName: 'com.siaa.mobile',
                          maxNativeZoom: _maxNativeZoomActual,
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
                                child: _buildVertexBadge(
                                  i + 1,
                                  state.verticesEtiquetados.length > i ? state.verticesEtiquetados[i] : null,
                                ),
                              ),

                            // Ubicación GPS real del usuario en vivo
                            if (state.currentPosition != null)
                              Marker(
                                point: ll.LatLng(state.currentPosition!.latitude, state.currentPosition!.longitude),
                                width: 40,
                                height: 40,
                                child: _buildGpsMarker(state.accuracyStatus),
                              ),
                          ],
                        ),

                        // Atribución oficial de capas
                        RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(_atribucionActual),
                          ],
                        ),
                      ],
                    ),

                    // ─── Controles Flotantes sobre el Mapa ───────────────────
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Column(
                        children: [
                          // Botón Rotar Capa (Google Híbrido -> Esri -> OSM)
                          _MapFloatingButton(
                            icon: _iconoCapaActual,
                            tooltip: 'Cambiar capa (Actual: $_nombreCapaActual)',
                            onPressed: _rotarCapaMapa,
                          ),
                          const SizedBox(height: 8),

                          // Botón Centrar en mi ubicación GPS
                          _MapFloatingButton(
                            icon: Icons.my_location,
                            tooltip: 'Mi ubicación GPS',
                            color: state.currentPosition != null ? Colors.cyanAccent : SIAAColors.neutral400,
                            onPressed: state.currentPosition != null
                                ? () {
                                    _mapController.move(
                                      ll.LatLng(state.currentPosition!.latitude, state.currentPosition!.longitude),
                                      19.5,
                                    );
                                  }
                                : () => _iniciarGps(),
                          ),
                          const SizedBox(height: 8),

                          // Botón Centrar en el polígono
                          if (state.vertices.isNotEmpty) ...[
                            _MapFloatingButton(
                              icon: Icons.crop_free,
                              tooltip: 'Ver polígono completo',
                              onPressed: () {
                                final bounds = LatLngBounds.fromPoints(
                                  state.vertices.map((v) => ll.LatLng(v[1], v[0])).toList(),
                                );
                                _mapController.fitCamera(
                                  CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Zoom In (+)
                          _MapFloatingButton(
                            icon: Icons.add,
                            tooltip: 'Acercar',
                            onPressed: () {
                              final currentZoom = _mapController.camera.zoom;
                              if (currentZoom < 22.5) {
                                _mapController.move(
                                  _mapController.camera.center,
                                  (currentZoom + 1).clamp(3.0, 22.5),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 8),

                          // Zoom Out (-)
                          _MapFloatingButton(
                            icon: Icons.remove,
                            tooltip: 'Alejar',
                            onPressed: () {
                              final currentZoom = _mapController.camera.zoom;
                              if (currentZoom > 3.0) {
                                _mapController.move(
                                  _mapController.camera.center,
                                  (currentZoom - 1).clamp(3.0, 22.5),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Tarjeta de métricas cartográficas ───────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MetricaItem(
                          label: 'Área estimada (AC-06)',
                          valor: '${state.areaCalculadaM2.toStringAsFixed(1)} m²',
                          icono: Icons.square_foot,
                          color: SIAAColors.primary600,
                        ),
                        _MetricaItem(
                          label: 'Perímetro',
                          valor: '${state.perimetroMetros.toStringAsFixed(1)} m',
                          icono: Icons.timeline,
                          color: SIAAColors.neutral700,
                        ),
                        _MetricaItem(
                          label: 'Precisión prom.',
                          valor: state.precisionPromedioCalculada != null
                              ? '${state.precisionPromedioCalculada!.toStringAsFixed(1)} m'
                              : 'N/A',
                          icono: Icons.gps_fixed,
                          color: state.precisionPromedioCalculada != null && state.precisionPromedioCalculada! <= 10
                              ? SIAAColors.asistenciaPresente
                              : SIAAColors.neutral500,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Botones de acción principales
                    Row(
                      children: [
                        // AC-05: Deshacer vértice
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.undo, size: 18),
                            label: const Text('Deshacer'),
                            onPressed: state.canUndo
                                ? () => context.read<GeoEditorBloc>().add(const DeshacerVerticeRequested())
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // AC-01: Capturar vértice por GPS (en modo recorrido)
                        if (state.modoCaptura == ModoCapturaEditor.recorrido)
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SIAAColors.primary600,
                                foregroundColor: Colors.white,
                              ),
                              icon: state.status == GeoEditorStatus.capturing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.add_location_alt, size: 18),
                              label: Text(
                                state.status == GeoEditorStatus.capturing
                                    ? 'Muestreando...'
                                    : 'Capturar Vértice',
                              ),
                              onPressed: state.canCapture
                                  ? () => context.read<GeoEditorBloc>().add(const CapturarVerticeRequested())
                                  : null,
                            ),
                          )
                        else
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: SIAAColors.primary200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.touch_app, size: 18, color: SIAAColors.primary600),
                                  SizedBox(width: 6),
                                  Text(
                                    'Toque mapa para marcar',
                                    style: TextStyle(
                                      color: SIAAColors.primary700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Cierre y guardado
                    Row(
                      children: [
                        // AC-06: Cerrar polígono
                        if (!state.isClosed)
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SIAAColors.neutral800,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Cerrar Polígono'),
                              onPressed: state.canClose
                                  ? () => context.read<GeoEditorBloc>().add(const CerrarPoligonoRequested())
                                  : null,
                            ),
                          ),

                        // AC-07: Guardar en el backend
                        if (state.isClosed) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SIAAColors.asistenciaPresente,
                                foregroundColor: Colors.white,
                              ),
                              icon: state.status == GeoEditorStatus.saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_upload, size: 18),
                              label: Text(
                                state.status == GeoEditorStatus.saving
                                    ? 'Guardando...'
                                    : 'Guardar Geometría',
                              ),
                              onPressed: state.status != GeoEditorStatus.saving
                                  ? () => context.read<GeoEditorBloc>().add(
                                        GuardarGeometriaBackendRequested(espacioId: widget.espacioId),
                                      )
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBannerPermisos() {
    if (_estadoPermiso == null || _estadoPermiso == EstadoPermisoUbicacion.concedido) {
      return const SizedBox.shrink();
    }

    String titulo;
    String accionTexto;
    VoidCallback onAccion;
    IconData icono;

    switch (_estadoPermiso!) {
      case EstadoPermisoUbicacion.servicioDesactivado:
        titulo = 'El GPS del dispositivo está desactivado. Actívelo para capturar vértices.';
        accionTexto = 'Activar GPS';
        onAccion = () => _gpsService.abrirAjustesUbicacion();
        icono = Icons.location_off;
        break;
      case EstadoPermisoUbicacion.denegadoPermanentemente:
        titulo = 'Permiso de ubicación denegado en ajustes del sistema. Habilítelo para usar el GPS.';
        accionTexto = 'Abrir Ajustes';
        onAccion = () => _gpsService.abrirAjustesAplicacion();
        icono = Icons.settings;
        break;
      case EstadoPermisoUbicacion.denegado:
      default:
        titulo = 'Se requiere permiso de ubicación para delimitar el espacio en sitio.';
        accionTexto = 'Conceder';
        onAccion = () => _iniciarGps();
        icono = Icons.location_searching;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color(0xFFDC2626), // Red 600
      child: Row(
        children: [
          Icon(icono, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 30),
            ),
            onPressed: onAccion,
            child: Text(accionTexto, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsMarker(GpsAccuracyStatus accuracy) {
    Color color;
    switch (accuracy) {
      case GpsAccuracyStatus.optimal:
        color = SIAAColors.asistenciaPresente;
        break;
      case GpsAccuracyStatus.acceptable:
        color = Colors.amber;
        break;
      case GpsAccuracyStatus.insufficient:
      default:
        color = SIAAColors.asistenciaAusente;
        break;
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.25),
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
          ),
        ),
      ],
    );
  }

  Widget _buildVertexBadge(int index, TaggedVertex? vertex) {
    final isGps = vertex?.origen == OrigenVertice.gps;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isGps ? const Color(0xFF2563EB) : const Color(0xFFD97706),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 3)],
      ),
      child: Text(
        '$index',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildModoMapaBadge(GeoEditorState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.map, size: 14, color: Colors.cyanAccent),
          SizedBox(width: 6),
          Text(
            'Mapa Interactivo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodoBadge(String metodo) {
    Color bg;
    Color fg;
    switch (metodo) {
      case 'TOQUE_MAPA':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case 'MIXTO':
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7E22CE);
        break;
      default:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        metodo,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  void _confirmarReinicio(BuildContext context) {
    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: const Text('¿Reiniciar polígono?'),
        content: const Text('Se descartarán todos los vértices capturados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SIAAColors.asistenciaAusente),
            onPressed: () {
              Navigator.of(dlgContext).pop();
              context.read<GeoEditorBloc>().add(const LimpiarVerticesRequested());
            },
            child: const Text('Reiniciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _MapFloatingButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _MapFloatingButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.90),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? Colors.white, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

class _MetricaItem extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  final Color color;

  const _MetricaItem({
    required this.label,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: color, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: SIAAColors.neutral500)),
            Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }
}
