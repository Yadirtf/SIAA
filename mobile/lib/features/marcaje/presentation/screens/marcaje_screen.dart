// marcaje_screen.dart — Pantalla principal de marcaje de un solo toque (US-MAR-01..US-MAR-15)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/marcaje_bloc.dart';
import '../bloc/marcaje_event.dart';
import '../bloc/marcaje_state.dart';
import '../widgets/one_touch_button.dart';
import '../widgets/rejection_dialog.dart';
import '../widgets/sesion_card.dart';
import '../widgets/sync_status_bar.dart';
import '../widgets/traffic_light_badge.dart';

class MarcajeScreen extends StatefulWidget {
  const MarcajeScreen({super.key});

  @override
  State<MarcajeScreen> createState() => _MarcajeScreenState();
}

class _MarcajeScreenState extends State<MarcajeScreen> {
  late final MarcajeBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = MarcajeBloc()..add(const CargarSesionActivaEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _onMarcarPressed(MarcajeState state) {
    final sesion = state.sesionActiva;
    if (sesion == null) return;

    final tipo = sesion.tieneMarcajeEntrada ? 'SALIDA' : 'ENTRADA';
    _bloc.add(RealizarMarcajeEvent(tipo: tipo));
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
        body: BlocConsumer<MarcajeBloc, MarcajeState>(
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
            if (res != null) {
              if (res.esRechazado || res.esPrecisionInsuficiente) {
                RejectionDialog.show(
                  context,
                  resultado: res,
                  onReintentar: () => _bloc.add(const CapturarUbicacionEvent()),
                  onJustificar: () {
                    // Navegación hacia justificaciones (F3)
                  },
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
                    content: Text('¡Marcaje registrado y verificado exitosamente!'),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SyncStatusBar(
                      count: state.colaOfflineCount,
                      onSyncPressed: () => _bloc.add(const SincronizarOfflineEvent()),
                    ),
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
                        onPressed: state.puedeMarcar ? () => _onMarcarPressed(state) : null,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, size: 72, color: Colors.grey.shade400),
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
