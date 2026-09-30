// revision_justificaciones_screen.dart — Bandeja de revisión de justificaciones del ámbito
// (RF-JUS-002). Visible con justificacion:aprobar.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/estado_vista.dart';
import '../../../justificaciones/domain/models/justificacion_model.dart';
import '../../../justificaciones/presentation/widgets/estado_justificacion_chip.dart';
import '../../../justificaciones/presentation/widgets/filtro_estado_bar.dart';
import '../../../justificaciones/presentation/widgets/formato_fechas.dart';
import '../../data/revision_remote_datasource.dart';
import '../cubit/revision_lista_cubit.dart';
import 'revision_detalle_screen.dart';

class RevisionJustificacionesScreen extends StatelessWidget {
  final RevisionRemoteDataSource? remote;

  const RevisionJustificacionesScreen({super.key, this.remote});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RevisionListaCubit(remote: remote)..cargar(),
      child: const _RevisionView(),
    );
  }
}

class _RevisionView extends StatelessWidget {
  const _RevisionView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RevisionListaCubit>();
    return BlocBuilder<RevisionListaCubit, RevisionListaState>(
      builder: (context, state) => Column(
        children: [
          FiltroEstadoBar(
            seleccionado: state.filtro,
            onCambiar: cubit.cambiarFiltro,
          ),
          Expanded(child: _cuerpo(context, state)),
        ],
      ),
    );
  }

  Widget _cuerpo(BuildContext context, RevisionListaState state) {
    final cubit = context.read<RevisionListaCubit>();
    switch (state.estado) {
      case EstadoRevisionLista.cargando:
        return const Center(child: CircularProgressIndicator());
      case EstadoRevisionLista.error:
        return EstadoError(
          mensaje: state.error ?? 'No se pudieron cargar las justificaciones.',
          onReintentar: cubit.cargar,
        );
      case EstadoRevisionLista.listo:
        if (state.items.isEmpty) {
          return const EstadoVacio(
            icono: Icons.fact_check_outlined,
            mensaje: 'No hay justificaciones en este estado',
          );
        }
        return RefreshIndicator(
          onRefresh: cubit.cargar,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: state.items.length,
            itemBuilder: (context, i) =>
                _tarjeta(context, state, state.items[i]),
          ),
        );
    }
  }

  Widget _tarjeta(
      BuildContext context, RevisionListaState state, Justificacion j) {
    final cubit = context.read<RevisionListaCubit>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(state.nombreDocente(j.docenteId),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${j.nombreSesion.isNotEmpty ? j.nombreSesion : 'Sesión'}\n'
          '${j.tipoEtiqueta} · Sesión del ${formatearFechaSesion(j.fechaSesion)}',
        ),
        isThreeLine: true,
        trailing: EstadoJustificacionChip(estado: j.estado),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RevisionDetalleScreen(
              justificacion: j,
              nombres: cubit.nombres,
            ),
          ));
          cubit.cargar();
        },
      ),
    );
  }
}
