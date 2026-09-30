// marcaje_screen.dart — Pantalla principal de marcaje de un solo toque (US-MAR-01..US-MAR-15)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../justificaciones/presentation/screens/justificacion_form_screen.dart';
import '../../../privacidad/data/consentimiento_gate.dart';
import '../../../privacidad/presentation/cubit/consentimiento_cubit.dart';
import '../../../privacidad/presentation/screens/aviso_privacidad_screen.dart';
import '../../../privacidad/presentation/widgets/consentimiento_banner.dart';
import '../../data/services/marcaje_sync_service.dart';
import '../../domain/models/marcaje_result_model.dart';
import '../../domain/models/offline_marcaje_item.dart';
import '../bloc/marcaje_bloc.dart';
import '../bloc/marcaje_event.dart';
import '../bloc/marcaje_state.dart';
import '../helpers/verificacion_resolver.dart';
import '../widgets/cola_offline_panel.dart';
import '../widgets/one_touch_button.dart';
import '../widgets/rejection_dialog.dart';
import '../widgets/sesion_card.dart';
import '../widgets/sync_status_bar.dart';
import '../widgets/traffic_light_badge.dart';

class MarcajeScreen extends StatefulWidget {
  /// Sesión indicada por una notificación (US-MAR-12); null al entrar normalmente.
  final String? sesionIdObjetivo;

  const MarcajeScreen({super.key, this.sesionIdObjetivo});

  @override
  State<MarcajeScreen> createState() => _MarcajeScreenState();
}

class _MarcajeScreenState extends State<MarcajeScreen> {
  late final MarcajeBloc _bloc;
  late final StreamSubscription<void> _colaSub;
  final _verificacionResolver = VerificacionResolver();
  MarcajeResultModel? _resultadoMostrado;
  int _rechazosAtendidos = 0;
  late bool _objetivoPendiente = widget.sesionIdObjetivo != null;

  @override
  void initState() {
    super.initState();
    _bloc = MarcajeBloc()
      ..add(const CargarSesionActivaEvent())
      ..add(const SincronizarOfflineEvent());
    // Sincronizaciones disparadas por red/ciclo de vida fuera de esta pantalla.
    _colaSub = MarcajeSyncService.actualizaciones
        .listen((_) => _bloc.add(const RefrescarColaOfflineEvent()));
    // Al aceptar/rechazar el aviso se reevalúa la sesión (y la captura GPS).
    ConsentimientoGate.instance.cambios.addListener(_recargar);
  }

  @override
  void didUpdateWidget(MarcajeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sesionIdObjetivo != oldWidget.sesionIdObjetivo) {
      _objetivoPendiente = widget.sesionIdObjetivo != null;
      _recargar();
    }
  }

  void _recargar() => _bloc.add(const CargarSesionActivaEvent());

  /// 403 CONSENTIMIENTO_REQUERIDO en línea: se reconsulta y se presenta el aviso.
  Future<void> _solicitarConsentimiento() async {
    await context.read<ConsentimientoCubit>().requerirDeNuevo();
    if (!mounted || AvisoPrivacidadScreen.visible) return;
    await AvisoPrivacidadScreen.mostrar(context);
  }

  /// La notificación apuntaba a una sesión que no es la activa en este momento.
  void _avisarSesionObjetivo(MarcajeState state) {
    final objetivo = widget.sesionIdObjetivo;
    if (objetivo == null || state.sesionActiva?.id == objetivo) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
          'La sesión de la notificación no tiene la ventana de marcaje abierta en este momento.'),
    ));
  }

  @override
  void dispose() {
    ConsentimientoGate.instance.cambios.removeListener(_recargar);
    _colaSub.cancel();
    _bloc.close();
    super.dispose();
  }

  Future<void> _onMarcarPressed(MarcajeState state) async {
    final sesion = state.sesionActiva;
    if (sesion == null) return;

    final tipo = sesion.tieneMarcajeEntrada ? 'SALIDA' : 'ENTRADA';
    final res = await _verificacionResolver.resolver(context, sesion);
    if (res.cancelado) return;
    _bloc.add(RealizarMarcajeEvent(tipo: tipo, verificacion: res.verificacion));
  }

  void _justificarOffline(OfflineMarcajeItem item) {
    JustificacionFormScreen.abrir(context, sesionId: item.request.sesionId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Marcaje de Asistencia'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualizar GPS y sesión',
              onPressed: () {
                _bloc.add(const CargarSesionActivaEvent());
              },
            ),
          ],
        ),
        body: BlocListener<MarcajeBloc, MarcajeState>(
          listenWhen: (prev, curr) =>
              prev.rechazosPorConsentimiento !=
                  curr.rechazosPorConsentimiento ||
              (prev.isLoading && !curr.isLoading),
          listener: (context, state) {
            if (state.rechazosPorConsentimiento > _rechazosAtendidos) {
              _rechazosAtendidos = state.rechazosPorConsentimiento;
              _solicitarConsentimiento();
            }
            if (!state.isLoading && _objetivoPendiente) {
              _objetivoPendiente = false;
              _avisarSesionObjetivo(state);
            }
          },
          child: BlocConsumer<MarcajeBloc, MarcajeState>(
            // Solo reaccionar a errores/resultados nuevos (no a refrescos de la cola).
            listenWhen: (prev, curr) =>
                prev.error != curr.error ||
                !identical(prev.ultimoResultado, curr.ultimoResultado),
            listener: (context, state) {
              if (state.error != null && !state.isCapturingGps) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error!),
                    backgroundColor: Colors.red.shade800,
                  ),
                );
              }

              final res = state.ultimoResultado;
              if (res != null && !identical(res, _resultadoMostrado)) {
                _resultadoMostrado = res;
                if (res.esRechazado || res.esPrecisionInsuficiente) {
                  RejectionDialog.show(
                    context,
                    resultado: res,
                    onReintentar: () =>
                        _bloc.add(const CapturarUbicacionEvent()),
                    onJustificar: state.sesionActiva == null
                        ? null
                        : () => JustificacionFormScreen.abrir(
                              context,
                              sesionId: state.sesionActiva!.id,
                              nombreSesion: state.sesionActiva!.asignatura,
                            ),
                  );
                } else if (res.resultado == 'PENDIENTE_SINCRONIZACION') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.mensaje),
                      backgroundColor: Colors.amber.shade800,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } else if (res.esAceptado) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          '¡Marcaje registrado y verificado exitosamente!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            builder: (context, state) {
              if (state.isLoading && state.sesionActiva == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _bloc.add(const CargarSesionActivaEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SyncStatusBar(
                        count: state.colaOfflineCount,
                        onSyncPressed: () =>
                            _bloc.add(const SincronizarOfflineEvent()),
                      ),
                      ColaOfflinePanel(
                        rechazados: state.colaRechazados,
                        fallidos: state.colaFallidos,
                        onJustificar: _justificarOffline,
                        onReintentar: (it) => _bloc
                            .add(ReintentarMarcajeOfflineEvent(it.localId)),
                      ),
                      if (state.consentimientoRequerido)
                        const ConsentimientoBanner(),
                      const SizedBox(height: 8),
                      Center(
                        child: TrafficLightBadge(
                          semaforo: state.semaforo,
                          precision: state.location?.precisionMetros,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (state.sesionActiva != null) ...[
                        SesionCard(sesion: state.sesionActiva!),
                        const SizedBox(height: 32),
                        OneTouchButton(
                          onPressed: state.puedeMarcar
                              ? () => _onMarcarPressed(state)
                              : null,
                          isSubmitting: state.isSubmitting,
                          isEnabled: state.puedeMarcar,
                          label: state.sesionActiva!.tieneMarcajeEntrada
                              ? 'MARCAR SALIDA'
                              : 'MARCAR ENTRADA',
                          icon: state.sesionActiva!.tieneMarcajeEntrada
                              ? Icons.logout_rounded
                              : Icons.touch_app_rounded,
                        ),
                      ] else ...[
                        const SizedBox(height: 48),
                        _buildEmptyState(),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.event_available_rounded,
              size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Sin Sesión Activa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay clases programadas en ventana de marcaje en este momento.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _bloc.add(const CargarSesionActivaEvent()),
            icon: const Icon(Icons.refresh),
            label: const Text('Comprobar nuevamente'),
          ),
        ],
      ),
    );
  }
}
