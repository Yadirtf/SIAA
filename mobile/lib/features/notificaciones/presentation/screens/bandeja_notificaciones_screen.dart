// bandeja_notificaciones_screen.dart — Bandeja de notificaciones en la app (US-NOT-01/02)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/bandeja_cubit.dart';
import '../cubit/bandeja_state.dart';
import '../notificacion_navegador.dart';
import '../widgets/notificacion_tile.dart';
import 'preferencias_notificacion_screen.dart';

class BandejaNotificacionesScreen extends StatefulWidget {
  const BandejaNotificacionesScreen({super.key});

  @override
  State<BandejaNotificacionesScreen> createState() =>
      _BandejaNotificacionesScreenState();
}

class _BandejaNotificacionesScreenState
    extends State<BandejaNotificacionesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BandejaCubit>().cargar();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BandejaCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Preferencias',
            onPressed: () => PreferenciasNotificacionScreen.abrir(context),
          ),
        ],
      ),
      body: BlocBuilder<BandejaCubit, BandejaState>(
        builder: (context, state) {
          if (state.cargando && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: cubit.cargar,
            child: state.items.isEmpty
                ? ListView(children: [_vacio(state.error)])
                : ListView.separated(
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final n = state.items[i];
                      return NotificacionTile(
                        notificacion: n,
                        onTap: () async {
                          final destino = await cubit.abrir(n);
                          if (!context.mounted) return;
                          context
                              .read<NotificacionNavegador>()
                              .solicitar(destino);
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _vacio(String? error) => Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              error ?? 'No tiene notificaciones.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
