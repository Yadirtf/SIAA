// espacios_screen.dart — Listado jerárquico Sede → Bloque → Piso → Aula (§9.1, US-GEO-01)
// Consulta con aula:leer; con aula:editar-geometria cada aula abre el editor GPS.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/estado_vista.dart';
import '../../../auth/presentation/permisos_sesion.dart';
import '../../../geo_editor/data/espacio_repository.dart';
import '../../../home/presentation/navigation/geo_editor_navigator.dart';
import '../cubit/espacios_jerarquia_cubit.dart';
import '../widgets/sede_expansion_tile.dart';

class EspaciosScreen extends StatelessWidget {
  final EspacioRepository? repository;

  const EspaciosScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          EspaciosJerarquiaCubit(repository: repository)..cargarSedes(),
      child: const _EspaciosView(),
    );
  }
}

class _EspaciosView extends StatelessWidget {
  const _EspaciosView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EspaciosJerarquiaCubit>();
    final puedeEditar = tienePermiso(context, 'aula:editar-geometria');
    return BlocBuilder<EspaciosJerarquiaCubit, EspaciosJerarquiaState>(
      builder: (context, state) {
        switch (state.estado) {
          case EstadoCarga.cargando:
            return const Center(child: CircularProgressIndicator());
          case EstadoCarga.error:
            return EstadoError(
              mensaje: state.error ?? 'No se pudieron cargar las sedes.',
              onReintentar: cubit.cargarSedes,
            );
          case EstadoCarga.listo:
            if (state.sedes.isEmpty) {
              return const EstadoVacio(
                icono: Icons.apartment_rounded,
                mensaje: 'No hay sedes registradas',
                detalle: 'Créalas desde "Editor GPS" o la consola web.',
              );
            }
            return RefreshIndicator(
              onRefresh: cubit.cargarSedes,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final sede in state.sedes)
                    SedeExpansionTile(
                      sede: sede,
                      detalle: state.detalles[sede.id],
                      onExpandir: () => cubit.cargarSede(sede.id),
                      onEditarPoligono: puedeEditar
                          ? (esp) => GeoEditorNavigator.navegar(
                                context: context,
                                espacio: esp,
                                espacioRepo: EspacioRepository(),
                                onRetorno: () =>
                                    cubit.cargarSede(sede.id, forzar: true),
                              )
                          : null,
                    ),
                ],
              ),
            );
        }
      },
    );
  }
}
