// justificacion_detalle_screen.dart — Detalle, soportes, historial y observaciones
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/justificacion_repository.dart';
import '../../domain/models/justificacion_model.dart';
import '../../domain/models/soporte_adjunto.dart';
import '../cubit/justificacion_detalle_cubit.dart';
import '../widgets/estado_justificacion_chip.dart';
import '../widgets/formato_fechas.dart';
import '../widgets/historial_justificacion_timeline.dart';

class JustificacionDetalleScreen extends StatelessWidget {
  final Justificacion justificacion;
  final JustificacionRepository? repository;

  const JustificacionDetalleScreen({
    super.key,
    required this.justificacion,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JustificacionDetalleCubit(
        repository ?? JustificacionRepository(),
        justificacion,
      )..cargar(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Detalle de justificación')),
        body: BlocBuilder<JustificacionDetalleCubit, JustificacionDetalleState>(
          builder: (context, state) => RefreshIndicator(
            onRefresh: context.read<JustificacionDetalleCubit>().cargar,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.cargando) const LinearProgressIndicator(),
                if (state.error != null) _aviso(state.error!),
                ..._contenido(state.justificacion),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _contenido(Justificacion j) {
    return [
      Row(
        children: [
          Expanded(
            child: Text(
              j.nombreSesion.isNotEmpty ? j.nombreSesion : 'Sesión',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          EstadoJustificacionChip(estado: j.estado),
        ],
      ),
      const SizedBox(height: 4),
      Text(
          'Sesión del ${formatearFechaSesion(j.fechaSesion)} • ${j.tipoEtiqueta}'),
      if (j.observaciones != null) ...[
        const SizedBox(height: 16),
        _observaciones(j),
      ],
      _seccion('Descripción'),
      Text(j.descripcion),
      _seccion('Soportes (${j.adjuntos.length})'),
      for (final a in j.adjuntos)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(a.esPdf ? Icons.picture_as_pdf : Icons.image),
          title: Text(a.nombre, overflow: TextOverflow.ellipsis),
          subtitle: Text(formatearTamano(a.tamano)),
        ),
      _seccion('Historial'),
      HistorialJustificacionTimeline(historial: j.historial),
    ];
  }

  Widget _observaciones(Justificacion j) {
    final (fondo, texto) = coloresEstadoJustificacion(j.estado);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Observaciones del revisor',
            style: TextStyle(fontWeight: FontWeight.bold, color: texto),
          ),
          const SizedBox(height: 4),
          Text(j.observaciones!),
        ],
      ),
    );
  }

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      );

  Widget _aviso(String mensaje) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(mensaje, style: TextStyle(color: Colors.red.shade700)),
      );
}
