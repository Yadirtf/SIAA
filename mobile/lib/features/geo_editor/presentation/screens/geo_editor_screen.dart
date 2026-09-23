import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/theme/app_theme.dart';
import '../../data/espacio_repository.dart';
import '../../domain/models/capa_mapa.dart';
import '../../domain/services/gps_location_service.dart';
import '../bloc/geo_editor_bloc.dart';
import '../bloc/geo_editor_event.dart';
import '../bloc/geo_editor_state.dart';
import '../widgets/dialogs/confirmar_reinicio_dialog.dart';
import '../widgets/dialogs/historial_versiones_dialog.dart';
import '../widgets/dialogs/solapamiento_dialogs.dart';
import '../widgets/geo_editor_bottom_panel.dart';
import '../widgets/geo_editor_header.dart';
import '../widgets/location_permission_banner.dart';
import '../widgets/map/geo_editor_map_view.dart';

export '../../domain/models/capa_mapa.dart';

/// Pantalla interactiva y coordinadora de levantamiento cartográfico perimetral (US-GEO-02, US-GEO-03, US-GEO-05, US-GEO-06, US-GEO-07).
/// Orquesta los componentes modulares de mapa, telemetría, permisos, edición de vértices y diálogos de solapamiento.
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
    if (widget.coordenadasExistentes != null && widget.coordenadasExistentes!.isNotEmpty) {
      _mapaCentradoInicialmente = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _cargarGeometria(widget.coordenadasExistentes!);
      });
    } else {
      EspacioRepository().obtenerEspacioPorId(widget.espacioId).then((esp) {
        if (mounted && esp.coordenadas != null && esp.coordenadas!.isNotEmpty) {
          _cargarGeometria(esp.coordenadas!);
        }
      }).catchError((_) {});
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

  void _rotarCapaMapa() {
    setState(() {
      _capaActual = _capaActual.siguiente;
    });
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
    // US-GEO-07 AC-05: Si se sale sin guardar, pedir confirmación y no alterar nada
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SIAAColors.neutral900,
        title: const Text('¿Descartar cambios no guardados?'),
        content: const Text(
          'Tiene un levantamiento cartográfico en progreso. Si sale ahora, las modificaciones se perderán sin alterar el espacio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SIAAColors.asistenciaAusente),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Descartar y salir'),
          ),
        ],
      ),
    );
    return salir ?? false;
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
          SolapamientoDialogs.mostrarCritico(context, state.solapamientoCritico!);
          return;
        }

        // US-GEO-05 AC-01 & AC-02: Advertencia ante solapamiento <= 50% con confirmación
        if (state.solapamientoAdvertencia != null) {
          SolapamientoDialogs.mostrarAdvertencia(
            context,
            advertencia: state.solapamientoAdvertencia!,
            detalles: state.solapamientoDetalles,
            onConfirmar: (motivo) {
              context.read<GeoEditorBloc>().add(
                    GuardarGeometriaBackendRequested(
                      espacioId: widget.espacioId,
                      confirmarSolapamiento: true,
                      motivoSolapamiento: motivo,
                    ),
                  );
            },
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
                // US-GEO-06 AC-04: Botón de consulta de versiones archivadas
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  tooltip: 'Historial de versiones (US-GEO-06)',
                  onPressed: () {
                    context.read<GeoEditorBloc>().add(CargarVersionesHistoricasRequested(widget.espacioId));
                    HistorialVersionesDialog.mostrar(
                      context,
                      versiones: state.versionesHistoricas,
                      versionActivaPreview: state.versionPreview?.version,
                      onSeleccionarPreview: (version) {
                        context.read<GeoEditorBloc>().add(SeleccionarVersionPreviewRequested(version));
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reiniciar polígono',
                  onPressed: state.vertices.isNotEmpty
                      ? () => ConfirmarReinicioDialog.mostrar(
                            context,
                            onConfirmar: () =>
                                context.read<GeoEditorBloc>().add(const LimpiarVerticesRequested()),
                          )
                      : null,
                ),
              ],
            ),
            body: Column(
              children: [
                // ─── Banner de Permisos de Ubicación (si no están concedidos) ─────
                LocationPermissionBanner(
                  estadoPermiso: _estadoPermiso,
                  onAbrirAjustesUbicacion: () => _gpsService.abrirAjustesUbicacion(),
                  onAbrirAjustesAplicacion: () => _gpsService.abrirAjustesAplicacion(),
                  onSolicitarPermiso: () => _iniciarGps(),
                ),

                // ─── Selector de modo de captura y barra de telemetría ────────────
                GeoEditorHeader(
                  state: state,
                  onModoChanged: (nuevoModo) {
                    context.read<GeoEditorBloc>().add(CambiarModoCapturaRequested(nuevoModo));
                  },
                ),

                // ─── Mapa interactivo real con capas y controles flotantes ────────
                Expanded(
                  child: GeoEditorMapView(
                    mapController: _mapController,
                    state: state,
                    capaActual: _capaActual,
                    onRotarCapa: _rotarCapaMapa,
                    onIniciarGps: _iniciarGps,
                    onMapTap: (longitud, latitud) {
                      context.read<GeoEditorBloc>().add(
                            ToqueEnMapaRequested(
                              longitud: longitud,
                              latitud: latitud,
                            ),
                          );
                    },
                    onSelectVertex: (index) {
                      if (index == -1 || state.verticeSeleccionadoIndex == index) {
                        context.read<GeoEditorBloc>().add(const SeleccionarVerticeRequested(null));
                      } else {
                        context.read<GeoEditorBloc>().add(SeleccionarVerticeRequested(index));
                      }
                    },
                    onDeleteVertex: (index) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: SIAAColors.neutral900,
                          title: Text('Eliminar vértice #${index + 1}'),
                          content: const Text(
                            '¿Desea eliminar este vértice? (Solo permitido si el polígono conserva más de 3 vértices)',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: SIAAColors.asistenciaAusente),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                context.read<GeoEditorBloc>().add(EliminarVerticeRequested(index));
                              },
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
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

                // ─── Tarjeta de métricas cartográficas y acciones ─────────────────
                GeoEditorBottomPanel(
                  state: state,
                  onDeshacer: () =>
                      context.read<GeoEditorBloc>().add(const DeshacerVerticeRequested()),
                  onCapturar: () =>
                      context.read<GeoEditorBloc>().add(const CapturarVerticeRequested()),
                  onCerrarPoligono: () =>
                      context.read<GeoEditorBloc>().add(const CerrarPoligonoRequested()),
                  onGuardar: () => context.read<GeoEditorBloc>().add(
                        GuardarGeometriaBackendRequested(espacioId: widget.espacioId),
                      ),
                  onSelectVertex: (index) {
                    if (index >= 0 && index < state.vertices.length) {
                      final v = state.vertices[index];
                      _mapController.move(ll.LatLng(v[1], v[0]), _mapController.camera.zoom);
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

