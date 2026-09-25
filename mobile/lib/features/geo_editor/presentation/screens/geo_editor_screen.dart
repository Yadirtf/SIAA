import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../domain/models/capa_mapa.dart';
import '../../domain/services/gps_location_service.dart';
import '../bloc/geo_editor_bloc.dart';
import '../bloc/geo_editor_event.dart';
import '../bloc/geo_editor_listener_handler.dart';
import '../bloc/geo_editor_state.dart';
import '../widgets/dialogs/confirmar_descarte_dialog.dart';
import '../widgets/dialogs/eliminar_vertice_dialog.dart';
import '../widgets/geo_editor_app_bar.dart';
import '../widgets/geo_editor_bottom_panel.dart';
import '../widgets/geo_editor_header.dart';
import '../widgets/location_permission_banner.dart';
import '../widgets/map/geo_editor_map_view.dart';

export '../../domain/models/capa_mapa.dart';

/// Pantalla coordinadora de levantamiento cartográfico perimetral.
/// Orquesta los componentes modulares de mapa, telemetría, permisos y edición.
class GeoEditorScreen extends StatefulWidget {
  final String espacioId;
  final String espacioCodigo;
  final String espacioNombre;
  final List<List<double>>? coordenadasExistentes;

  const GeoEditorScreen({
    super.key,
    required this.espacioId,
    required this.espacioCodigo,
    required this.espacioNombre,
    this.coordenadasExistentes,
  });

  @override
  State<GeoEditorScreen> createState() => _GeoEditorScreenState();
}

class _GeoEditorScreenState extends State<GeoEditorScreen> {
  final GpsLocationService _gpsService = GpsLocationService();
  final MapController _mapController = MapController();

  EstadoPermisoUbicacion? _estadoPermiso;
  CapaMapa _capaActual = CapaMapa.googleHibrido;
  bool _mapaCentradoInicialmente = false;

  @override
  void initState() {
    super.initState();
    if (widget.coordenadasExistentes != null &&
        widget.coordenadasExistentes!.isNotEmpty) {
      _mapaCentradoInicialmente = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _cargarGeometria(widget.coordenadasExistentes!);
      });
    }
    _iniciarGps();
  }

  void _cargarGeometria(List<List<double>> coords) {
    if (coords.isEmpty) return;
    _mapaCentradoInicialmente = true;
    context.read<GeoEditorBloc>().add(
          CargarGeometriaExistenteRequested(coords),
        );
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      _centrarEnCoordenadas(coords);
    });
  }

  void _centrarEnCoordenadas(List<List<double>> coords) {
    if (coords.isEmpty) return;
    try {
      final points = coords.map((c) => ll.LatLng(c[1], c[0])).toList();
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    } catch (_) {
      _mapController.move(ll.LatLng(coords.first[1], coords.first[0]), 18.5);
    }
  }

  Future<void> _iniciarGps() async {
    try {
      final estado = await _gpsService.escucharPosicionesConPermiso(
        onReading: (reading) {
          if (!mounted) return;
          context.read<GeoEditorBloc>().add(GpsPositionUpdated(reading));
          if (!_mapaCentradoInicialmente) {
            _mapaCentradoInicialmente = true;
            try {
              _mapController.move(
                  ll.LatLng(reading.latitude, reading.longitude), 18.5);
            } catch (_) {}
          }
        },
        onError: (_) {},
      );

      if (mounted) setState(() => _estadoPermiso = estado);
    } catch (_) {}
  }

  void _rotarCapaMapa() {
    setState(() => _capaActual = _capaActual.siguiente);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Capa activa: ${_capaActual.nombre}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _confirmarSalidaSiHayCambios(GeoEditorState state) async {
    if (state.vertices.isEmpty || state.status == GeoEditorStatus.success) {
      return true;
    }
    return ConfirmarDescarteDialog.mostrar(context);
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
      listener: (ctx, state) => GeoEditorListenerHandler.manejarEstado(
        ctx,
        state,
        espacioId: widget.espacioId,
      ),
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final canExit = await _confirmarSalidaSiHayCambios(state);
            if (canExit && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: GeoEditorAppBar(
              espacioId: widget.espacioId,
              espacioCodigo: widget.espacioCodigo,
              espacioNombre: widget.espacioNombre,
              state: state,
            ),
            body: Column(
              children: [
                LocationPermissionBanner(
                  estadoPermiso: _estadoPermiso,
                  onAbrirAjustesUbicacion: () =>
                      _gpsService.abrirAjustesUbicacion(),
                  onAbrirAjustesAplicacion: () =>
                      _gpsService.abrirAjustesAplicacion(),
                  onSolicitarPermiso: () => _iniciarGps(),
                ),
                GeoEditorHeader(
                  state: state,
                  onModoChanged: (nuevoModo) {
                    context
                        .read<GeoEditorBloc>()
                        .add(CambiarModoCapturaRequested(nuevoModo));
                  },
                ),
                Expanded(
                  child: GeoEditorMapView(
                    mapController: _mapController,
                    state: state,
                    capaActual: _capaActual,
                    onRotarCapa: _rotarCapaMapa,
                    onIniciarGps: _iniciarGps,
                    onMapTap: (lon, lat) {
                      context.read<GeoEditorBloc>().add(
                            ToqueEnMapaRequested(longitud: lon, latitud: lat),
                          );
                    },
                    onSelectVertex: (index) {
                      final selected = (index == -1 ||
                              state.verticeSeleccionadoIndex == index)
                          ? null
                          : index;
                      context
                          .read<GeoEditorBloc>()
                          .add(SeleccionarVerticeRequested(selected));
                    },
                    onDeleteVertex: (index) {
                      EliminarVerticeDialog.mostrar(
                        context,
                        verticeNumero: index + 1,
                        onConfirmar: () {
                          context
                              .read<GeoEditorBloc>()
                              .add(EliminarVerticeRequested(index));
                        },
                      );
                    },
                    onMoveVertex: (index, lon, lat) {
                      context.read<GeoEditorBloc>().add(
                            MoverVerticeRequested(
                              index: index,
                              nuevaLongitud: lon,
                              nuevaLatitud: lat,
                            ),
                          );
                    },
                    onInsertVertex: (indexDespuesDe, lon, lat) {
                      context.read<GeoEditorBloc>().add(
                            InsertarVerticeEnSegmentoRequested(
                              indexDespuesDe: indexDespuesDe,
                              longitud: lon,
                              latitud: lat,
                            ),
                          );
                    },
                  ),
                ),
                GeoEditorBottomPanel(
                  state: state,
                  onDeshacer: () => context
                      .read<GeoEditorBloc>()
                      .add(const DeshacerVerticeRequested()),
                  onCapturar: () => context
                      .read<GeoEditorBloc>()
                      .add(const CapturarVerticeRequested()),
                  onCerrarPoligono: () => context
                      .read<GeoEditorBloc>()
                      .add(const CerrarPoligonoRequested()),
                  onGuardar: () => context.read<GeoEditorBloc>().add(
                        GuardarGeometriaBackendRequested(
                            espacioId: widget.espacioId),
                      ),
                  onSelectVertex: (index) {
                    if (index >= 0 && index < state.vertices.length) {
                      final v = state.vertices[index];
                      _mapController.move(
                          ll.LatLng(v[1], v[0]), _mapController.camera.zoom);
                      context.read<GeoEditorBloc>().add(MoverVerticeRequested(
                            index: index,
                            nuevaLongitud: v[0],
                            nuevaLatitud: v[1],
                          ));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
