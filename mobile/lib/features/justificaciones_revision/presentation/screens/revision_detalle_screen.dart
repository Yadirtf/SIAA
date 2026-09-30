// revision_detalle_screen.dart — Detalle, soportes, historial y decisión (RF-JUS-002)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../justificaciones/domain/models/justificacion_model.dart';
import '../../../justificaciones/presentation/widgets/estado_justificacion_chip.dart';
import '../../../justificaciones/presentation/widgets/formato_fechas.dart';
import '../../../justificaciones/presentation/widgets/historial_justificacion_timeline.dart';
import '../../data/resolutor_nombres.dart';
import '../cubit/revision_detalle_cubit.dart';
import '../widgets/decision_revision_panel.dart';
import '../widgets/observaciones_dialog.dart';
import '../widgets/soporte_revision_tile.dart';

class RevisionDetalleScreen extends StatelessWidget {
  final Justificacion justificacion;
  final ResolutorNombres nombres;

  const RevisionDetalleScreen({
    super.key,
    required this.justificacion,
    required this.nombres,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          RevisionDetalleCubit(nombres.remote, nombres, justificacion)
            ..cargar(),
      child: const _DetalleView(),
    );
  }
}

class _DetalleView extends StatelessWidget {
  const _DetalleView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RevisionDetalleCubit, RevisionDetalleState>(
      builder: (context, state) {
        final j = state.justificacion;
        final cubit = context.read<RevisionDetalleCubit>();
        return Scaffold(
          appBar: AppBar(title: const Text('Revisar justificación')),
          bottomNavigationBar: DecisionRevisionPanel(
            puedeTomar: state.puedeTomar,
            puedeDecidir: state.puedeDecidir,
            procesando: state.procesando,
            onTomar: () => _resultado(context, cubit.tomarEnRevision()),
            onAprobar: () => _aprobar(context, cubit),
            onRechazar: () => _rechazar(context, cubit),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                      state.nombreDe(j.docenteId, porDefecto: 'Docente'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                EstadoJustificacionChip(estado: j.estado),
              ]),
              const SizedBox(height: 4),
              Text(j.nombreSesion.isNotEmpty ? j.nombreSesion : 'Sesión'),
              Text(
                  'Sesión del ${formatearFechaSesion(j.fechaSesion)} · ${j.tipoEtiqueta}'),
              if (j.creadoEn != null)
                Text('Radicada el ${formatearMomento(j.creadoEn!)}',
                    style: Theme.of(context).textTheme.bodySmall),
              _seccion('Descripción'),
              Text(j.descripcion),
              if (j.observaciones != null) ...[
                _seccion('Observaciones del revisor'),
                Text(j.observaciones!),
              ],
              _seccion('Soportes (${j.adjuntos.length})'),
              for (final a in j.adjuntos)
                SoporteRevisionTile(
                    adjunto: a, descargar: cubit.descargarSoporte),
              _seccion('Historial'),
              HistorialJustificacionTimeline(historial: j.historial),
            ],
          ),
        );
      },
    );
  }

  Future<void> _aprobar(
      BuildContext context, RevisionDetalleCubit cubit) async {
    final obs = await ObservacionesDialog.mostrar(context,
        titulo: 'Aprobar justificación', accion: 'Aprobar');
    if (obs == null || !context.mounted) return;
    await _resultado(context, cubit.aprobar(obs));
  }

  Future<void> _rechazar(
      BuildContext context, RevisionDetalleCubit cubit) async {
    final obs = await ObservacionesDialog.mostrar(context,
        titulo: 'Rechazar justificación',
        accion: 'Rechazar',
        minimo: RevisionDetalleCubit.minObservacionesRechazo);
    if (obs == null || !context.mounted) return;
    await _resultado(context, cubit.rechazar(obs));
  }

  Future<void> _resultado(BuildContext context, Future<String?> accion) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await accion;
    messenger.showSnackBar(SnackBar(
      content: Text(error ?? 'Decisión registrada'),
      backgroundColor: error == null ? null : Colors.red.shade700,
    ));
  }

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(titulo,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      );
}
