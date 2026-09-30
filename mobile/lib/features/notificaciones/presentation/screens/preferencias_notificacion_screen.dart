// preferencias_notificacion_screen.dart — Un interruptor por tipo de notificación (US-NOT-02)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/preferencias_notificacion.dart';
import '../cubit/preferencias_notificacion_cubit.dart';

class PreferenciasNotificacionScreen extends StatelessWidget {
  final PreferenciasNotificacionCubit? cubit;

  const PreferenciasNotificacionScreen({super.key, this.cubit});

  static Future<void> abrir(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const PreferenciasNotificacionScreen()));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? PreferenciasNotificacionCubit())..cargar(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Preferencias de notificación')),
        body: BlocConsumer<PreferenciasNotificacionCubit,
            PreferenciasNotificacionState>(
          listenWhen: (a, b) => b.error != null && a.error != b.error,
          listener: (context, state) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!))),
          builder: (context, state) {
            final p = state.preferencias;
            if (p == null) {
              return Center(
                child: state.cargando
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: () => context
                            .read<PreferenciasNotificacionCubit>()
                            .cargar(),
                        child: const Text('Reintentar'),
                      ),
              );
            }
            return ListView(
              children: [
                for (final clave in PreferenciasNotificacion.claves)
                  SwitchListTile(
                    key: ValueKey('pref-$clave'),
                    title: Text(PreferenciasNotificacion.etiquetas[clave]!),
                    subtitle: p.esObligatoria(clave)
                        ? const Text('Obligatoria institucional')
                        : null,
                    value: p.valor(clave),
                    onChanged: p.esObligatoria(clave) || state.guardando
                        ? null
                        : (v) => context
                            .read<PreferenciasNotificacionCubit>()
                            .cambiar(clave, v),
                  ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'La institución define una franja de silencio durante la '
                    'cual no se envían notificaciones.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
