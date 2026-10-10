// derechos_screen.dart — Mis datos y derechos: copia, rectificación y supresión (US-LEG-02)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/derechos_remote_datasource.dart';
import '../../data/guardar_archivo.dart';
import '../cubit/derechos_cubit.dart';
import '../cubit/derechos_state.dart';
import '../widgets/plazos_derechos_card.dart';
import '../widgets/rectificacion_dialog.dart';
import '../widgets/solicitud_derecho_tile.dart';
import '../widgets/supresion_dialog.dart';

class DerechosScreen extends StatelessWidget {
  final DerechosRemoteDataSource? remote;
  final GuardarArchivo? guardar;

  const DerechosScreen({super.key, this.remote, this.guardar});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DerechosCubit(
        remote: remote,
        guardar: guardar ?? guardarArchivoEnDispositivo,
      )..cargar(),
      child: BlocConsumer<DerechosCubit, DerechosState>(
        listenWhen: (a, b) => b.mensaje != null && a.mensaje != b.mensaje,
        listener: (context, state) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.mensaje!))),
        builder: (context, state) => _contenido(context, state),
      ),
    );
  }

  Future<void> _rectificar(BuildContext context) async {
    final cubit = context.read<DerechosCubit>();
    final pedido = await RectificacionDialog.mostrar(context);
    if (pedido == null) return;
    await cubit.radicar(
      tipo: 'RECTIFICACION',
      descripcion: pedido.descripcion,
      cambios: pedido.cambios,
    );
  }

  Future<void> _suprimir(BuildContext context) async {
    final cubit = context.read<DerechosCubit>();
    final motivo =
        await SupresionDialog.mostrar(context, cubit.state.evaluacion);
    if (motivo == null) return;
    await cubit.radicar(tipo: 'SUPRESION', descripcion: motivo);
  }

  Widget _contenido(BuildContext context, DerechosState state) {
    final cubit = context.read<DerechosCubit>();
    final tema = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: cubit.cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.cargando || state.enviando) const LinearProgressIndicator(),
          Text('Mis datos y derechos', style: tema.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Puede conocer, rectificar y pedir la supresión de sus datos '
            'personales (Ley 1581 de 2012).',
            style: tema.bodySmall,
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: state.enviando ? null : cubit.descargarCopia,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Descargar copia de mis datos'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: state.enviando || state.tieneAbierta('RECTIFICACION')
                ? null
                : () => _rectificar(context),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Solicitar rectificación'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: state.enviando || state.tieneAbierta('SUPRESION')
                ? null
                : () => _suprimir(context),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Solicitar supresión'),
          ),
          if (state.canal != null) ...[
            const SizedBox(height: 16),
            PlazosDerechosCard(canal: state.canal!),
          ],
          const SizedBox(height: 16),
          Text('Mis solicitudes', style: tema.titleMedium),
          const SizedBox(height: 8),
          if (state.solicitudes.isEmpty && !state.cargando)
            Text('No ha radicado solicitudes.', style: tema.bodySmall)
          else
            for (final s in state.solicitudes)
              SolicitudDerechoTile(solicitud: s),
        ],
      ),
    );
  }
}
