import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/aviso_panel.dart';
import '../../../../core/widgets/encabezado_seccion.dart';
import '../../../justificaciones/presentation/dialogs/observaciones_dialog.dart';
import '../../data/derechos_remote_datasource.dart';
import '../../data/models/solicitud_derecho_model.dart';
import '../bloc/solicitudes_derechos_cubit.dart';
import '../widgets/solicitud_derecho_card.dart';

/// Bandeja de solicitudes de rectificación y supresión de los titulares (US-LEG-02).
class SolicitudesDerechosScreen extends StatelessWidget {
  final DerechosRemoteDataSource? remote;

  const SolicitudesDerechosScreen({super.key, this.remote});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SolicitudesDerechosCubit(remote: remote)..cargar(),
      child: BlocConsumer<SolicitudesDerechosCubit, SolicitudesDerechosState>(
        listenWhen: (a, b) => b.mensaje != null && a.mensaje != b.mensaje,
        listener: (context, state) =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.mensaje!))),
        builder: (context, state) => _contenido(context, state),
      ),
    );
  }

  Future<void> _resolver(
    BuildContext context,
    SolicitudDerechoModel s, {
    required bool atendida,
  }) async {
    final cubit = context.read<SolicitudesDerechosCubit>();
    final respuesta = await ObservacionesDialog.show(
      context,
      titulo: atendida ? 'Atender solicitud' : 'Denegar solicitud',
      descripcion: atendida
          ? (s.tipo == 'SUPRESION'
                ? 'Se eliminarán las ubicaciones y los avisos del titular; lo demás se conserva por obligación legal.'
                : 'Los datos indicados se corregirán en la cuenta del titular.')
          : 'Explique al titular el motivo de la negativa.',
      textoConfirmar: atendida ? 'Atender' : 'Denegar',
      minimo: 10,
    );
    if (respuesta == null) return;
    await cubit.resolver(s.id, atendida: atendida, respuesta: respuesta);
  }

  Widget _contenido(BuildContext context, SolicitudesDerechosState state) {
    final cubit = context.read<SolicitudesDerechosCubit>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EncabezadoSeccion(
            icono: Icons.folder_shared_rounded,
            titulo: 'Derechos de titulares',
            subtitulo: 'Rectificación y supresión de datos personales con plazo legal (US-LEG-02)',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilterChip(
                label: const Text('Solo pendientes'),
                selected: state.soloAbiertas,
                onSelected: (v) => cubit.cargar(soloAbiertas: v),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Recargar',
                onPressed: cubit.cargar,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.error != null && state.solicitudes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (state.error != null && state.solicitudes.isEmpty)
            AvisoPanel.error(
              titulo: 'No fue posible completar la operación',
              detalle: state.error!,
              onReintentar: cubit.cargar,
            )
          else if (state.cargando && state.solicitudes.isEmpty)
            AvisoPanel.cargando()
          else if (state.solicitudes.isEmpty)
            const AvisoPanel(
              icono: Icons.inbox_rounded,
              titulo: 'Sin solicitudes',
              detalle: 'No hay solicitudes de titulares por atender.',
            )
          else
            for (final s in state.solicitudes)
              SolicitudDerechoCard(
                solicitud: s,
                onAsumir: () => cubit.asumir(s.id),
                onAtender: () => _resolver(context, s, atendida: true),
                onDenegar: () => _resolver(context, s, atendida: false),
              ),
        ],
      ),
    );
  }
}
