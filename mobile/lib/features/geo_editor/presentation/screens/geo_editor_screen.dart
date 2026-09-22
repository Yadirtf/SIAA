import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/capa_mapa.dart';
import '../../domain/services/gps_location_service.dart';
import '../bloc/geo_editor_bloc.dart';
import '../bloc/geo_editor_event.dart';
import '../bloc/geo_editor_state.dart';
import '../widgets/dialogs/confirmar_reinicio_dialog.dart';
import '../widgets/dialogs/solapamiento_dialogs.dart';
import '../widgets/geo_editor_bottom_panel.dart';
import '../widgets/geo_editor_header.dart';
import '../widgets/location_permission_banner.dart';
import '../widgets/map/geo_editor_map_view.dart';

export '../../domain/models/capa_mapa.dart';

/// Pantalla interactiva y coordinadora de levantamiento cartográfico perimetral (US-GEO-02, US-GEO-03, US-GEO-05).
/// Orquesta los componentes modulares de mapa, telemetría, permisos y diálogos de solapamiento.
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

class _GeoEditorScreenState extends State<GeoEditorScreen> {
  final GpsLocationService _gpsService = GpsLocationService();
  final MapController _mapController = MapController();

  EstadoPermisoUbicacion? _estadoPermiso;
  CapaMapa _capaActual = CapaMapa.googleHibrido;
  bool _mapaCentradoInicialmente = false;

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
              ),
            ],
          ),
        );
      },
    );
  }
}
