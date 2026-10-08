// mi_asistencia_section.dart — Sección "Mi asistencia" del perfil del estudiante
// (US-MAR-13 AC-05) con el porcentaje por asignatura desde GET /me/asistencia.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/asistencia_remote_datasource.dart';
import '../cubit/mi_asistencia_cubit.dart';
import 'asistencia_asignatura_tile.dart';

class MiAsistenciaSection extends StatelessWidget {
  final AsistenciaRemoteDataSource? remote;

  const MiAsistenciaSection({super.key, this.remote});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MiAsistenciaCubit(remote: remote)..cargar(),
      child: BlocBuilder<MiAsistenciaCubit, MiAsistenciaState>(
        builder: (context, state) {
          final gris =
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 24, bottom: 8),
                child: Text('Mi asistencia',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              if (state.cargando) const LinearProgressIndicator(),
              if (state.error != null)
                Row(children: [
                  Expanded(
                    child: Text(state.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                  TextButton(
                    onPressed: context.read<MiAsistenciaCubit>().cargar,
                    child: const Text('Reintentar'),
                  ),
                ]),
              if (!state.cargando &&
                  state.error == null &&
                  state.asignaturas.isEmpty)
                Text('Aún no tienes asignaturas con asistencia registrada.',
                    style: TextStyle(color: gris)),
              for (final a in state.asignaturas)
                AsistenciaAsignaturaTile(asistencia: a),
            ],
          );
        },
      ),
    );
  }
}
