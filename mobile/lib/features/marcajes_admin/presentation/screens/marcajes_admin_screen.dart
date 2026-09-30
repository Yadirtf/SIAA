// marcajes_admin_screen.dart — Consulta administrativa de marcajes con filtros, paginación,
// detalle y ajustes (US-MAR-09). Visible con marcaje:leer; acciones con marcaje:ajustar.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/estado_vista.dart';
import '../../../auth/presentation/permisos_sesion.dart';
import '../../../marcaje/domain/models/marcaje_historial_model.dart';
import '../../data/marcajes_admin_remote_datasource.dart';
import '../cubit/marcajes_admin_cubit.dart';
import '../cubit/marcajes_admin_state.dart';
import '../widgets/ajuste_marcaje_dialog.dart';
import '../widgets/filtros_marcajes_bar.dart';
import '../widgets/marcaje_admin_tile.dart';
import '../widgets/marcaje_detalle_sheet.dart';

class MarcajesAdminScreen extends StatelessWidget {
  final MarcajesAdminRemoteDataSource? remote;

  const MarcajesAdminScreen({super.key, this.remote});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MarcajesAdminCubit(remote: remote)..cargar(),
      child: const _MarcajesAdminView(),
    );
  }
}

class _MarcajesAdminView extends StatelessWidget {
  const _MarcajesAdminView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MarcajesAdminCubit>();
    return BlocBuilder<MarcajesAdminCubit, MarcajesAdminState>(
      builder: (context, state) => Column(
        children: [
          FiltrosMarcajesBar(
            filtro: state.filtro,
            onResultado: cubit.filtrarResultado,
            onFechas: cubit.filtrarFechas,
          ),
          if (state.estado == EstadoMarcajesAdmin.listo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${state.total} marcajes',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          Expanded(child: _cuerpo(context, state)),
        ],
      ),
    );
  }

  Widget _cuerpo(BuildContext context, MarcajesAdminState state) {
    final cubit = context.read<MarcajesAdminCubit>();
    switch (state.estado) {
      case EstadoMarcajesAdmin.cargando:
        return const Center(child: CircularProgressIndicator());
      case EstadoMarcajesAdmin.error:
        return EstadoError(
          mensaje: state.error ?? 'No se pudieron cargar los marcajes.',
          onReintentar: cubit.cargar,
        );
      case EstadoMarcajesAdmin.listo:
        if (state.items.isEmpty) {
          return const EstadoVacio(
            icono: Icons.manage_search_rounded,
            mensaje: 'No hay marcajes para los filtros seleccionados',
          );
        }
        return RefreshIndicator(
          onRefresh: cubit.cargar,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: state.items.length + (state.hayMas ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == state.items.length) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: state.cargandoMas
                        ? const CircularProgressIndicator()
                        : OutlinedButton(
                            onPressed: cubit.cargarMas,
                            child: const Text('Cargar más'),
                          ),
                  ),
                );
              }
              final item = state.items[i];
              return MarcajeAdminTile(
                item: item,
                onTap: () => _abrirDetalle(context, item),
              );
            },
          ),
        );
    }
  }

  void _abrirDetalle(BuildContext context, MarcajeHistorialItem item) {
    final puedeAjustar = tienePermiso(context, 'marcaje:ajustar');
    MarcajeDetalleSheet.mostrar(
      context,
      MarcajeDetalleSheet(
        item: item,
        onAnular:
            puedeAjustar ? () => _ajustar(context, item, anular: true) : null,
        onCorregir:
            puedeAjustar ? () => _ajustar(context, item, anular: false) : null,
      ),
    );
  }

  Future<void> _ajustar(BuildContext context, MarcajeHistorialItem item,
      {required bool anular}) async {
    final cubit = context.read<MarcajesAdminCubit>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(); // cierra el detalle
    final ajuste = await AjusteMarcajeDialog.mostrar(
      context,
      anular: anular,
      resultadoActual: item.resultado,
    );
    if (ajuste == null) return;
    final error = await cubit.ajustar(item.id, ajuste);
    messenger.showSnackBar(SnackBar(
      content:
          Text(error ?? (anular ? 'Marcaje anulado' : 'Resultado corregido')),
      backgroundColor: error == null ? null : Colors.red.shade700,
    ));
  }
}
