// solapamientos_screen.dart — Pares de aulas superpuestas con área y porcentaje (US-GEO-05)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/estado_vista.dart';
import '../../../geo_editor/data/espacio_repository.dart';
import '../../data/solapamientos_remote_datasource.dart';
import '../../domain/solapamiento_model.dart';
import '../cubit/solapamientos_cubit.dart';

class SolapamientosScreen extends StatelessWidget {
  final SolapamientosRemoteDataSource? remote;
  final EspacioRepository? espacios;

  const SolapamientosScreen({super.key, this.remote, this.espacios});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SolapamientosCubit(remote: remote, espacios: espacios)..cargar(),
      child: BlocBuilder<SolapamientosCubit, SolapamientosState>(
        builder: (context, state) {
          final cubit = context.read<SolapamientosCubit>();
          switch (state.estado) {
            case EstadoSolapamientos.cargando:
              return const Center(child: CircularProgressIndicator());
            case EstadoSolapamientos.error:
              return EstadoError(
                mensaje: state.error ?? 'No se pudo consultar el informe.',
                onReintentar: cubit.cargar,
              );
            case EstadoSolapamientos.listo:
              if (state.conflictos.isEmpty) {
                return const EstadoVacio(
                  icono: Icons.layers_clear_rounded,
                  mensaje: 'No hay aulas con polígonos superpuestos',
                );
              }
              return RefreshIndicator(
                onRefresh: cubit.cargar,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                          '${state.conflictos.length} conflictos detectados',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    for (final c in state.conflictos) _tarjeta(state, c),
                  ],
                ),
              );
          }
        },
      ),
    );
  }

  Widget _tarjeta(SolapamientosState state, SolapamientoModel c) {
    final color = c.esCritico ? Colors.red.shade700 : Colors.amber.shade800;
    final ubicacion = [
      state.nombreSede(c.sedeId),
      if (c.piso != null) 'Piso ${c.piso}',
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(Icons.layers_rounded, color: color),
        title: Text('${c.aula1}  ↔  ${c.aula2}'),
        subtitle: Text(
          '$ubicacion\n${c.areaSolapadaM2.toStringAsFixed(1)} m² superpuestos '
          '(${c.porcentajeSolapado.toStringAsFixed(1)} %)',
        ),
        isThreeLine: true,
        trailing: c.esCritico
            ? Text('CRÍTICO',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 11))
            : null,
      ),
    );
  }
}
