import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/aviso_panel.dart';
import '../../../../core/widgets/encabezado_seccion.dart';
import '../../../../core/widgets/paginacion_controles.dart';
import '../../data/models/justificacion_model.dart';
import '../bloc/justificaciones_cubit.dart';
import '../bloc/justificaciones_state.dart';
import '../dialogs/justificacion_detalle_dialog.dart';
import '../widgets/justificaciones_filtros_bar.dart';
import '../widgets/justificaciones_table.dart';

/// Bandeja de revisión de justificaciones para coordinadores (US-JUS-02/03).
class JustificacionesScreen extends StatefulWidget {
  /// true si el usuario tiene `justificacion:aprobar`.
  final bool puedeAprobar;

  const JustificacionesScreen({super.key, this.puedeAprobar = false});

  @override
  State<JustificacionesScreen> createState() => _JustificacionesScreenState();
}

class _JustificacionesScreenState extends State<JustificacionesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<JustificacionesCubit>().recargar();
  }

  Future<void> _ver(JustificacionModel j) async {
    final cubit = context.read<JustificacionesCubit>();
    final cambio = await JustificacionDetalleDialog.show(
      context,
      justificacion: j,
      puedeAprobar: widget.puedeAprobar,
      nombres: cubit.state.nombres,
    );
    if (cambio) await cubit.recargar();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JustificacionesCubit, JustificacionesState>(
      builder: (context, state) {
        final cubit = context.read<JustificacionesCubit>();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EncabezadoSeccion(
                icono: Icons.fact_check_rounded,
                titulo: 'Justificaciones',
                subtitulo:
                    'Bandeja de revisión de novedades docentes (US-JUS-02/03)',
              ),
              const SizedBox(height: 20),
              JustificacionesFiltrosBar(
                filtro: state.filtro,
                onFiltrar: cubit.cargar,
                onRecargar: cubit.recargar,
              ),
              const SizedBox(height: 16),
              _contenido(state, cubit),
            ],
          ),
        );
      },
    );
  }

  Widget _contenido(JustificacionesState state, JustificacionesCubit cubit) {
    switch (state.status) {
      case JustificacionesStatus.inicial:
      case JustificacionesStatus.cargando:
        return AvisoPanel.cargando();
      case JustificacionesStatus.error:
        return AvisoPanel.error(
          titulo: 'Error al consultar justificaciones',
          detalle: state.error ?? '',
          onReintentar: cubit.recargar,
        );
      case JustificacionesStatus.cargado:
        final pagina = state.pagina!;
        if (pagina.items.isEmpty && pagina.pagina == 1) {
          return const AvisoPanel(
            icono: Icons.inbox_rounded,
            titulo: 'No hay justificaciones',
            detalle: 'No hay novedades que coincidan con los filtros.',
          );
        }
        return Column(
          children: [
            JustificacionesTable(
              justificaciones: pagina.items,
              nombreDocente: state.nombreDe,
              onVer: _ver,
            ),
            const SizedBox(height: 8),
            PaginacionControles(
              pagina: pagina,
              sustantivo: 'justificaciones',
              onPagina: cubit.irAPagina,
            ),
          ],
        );
    }
  }
}
