import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/aviso_panel.dart';
import '../../../../core/widgets/botones_exportar.dart';
import '../../../../core/widgets/encabezado_seccion.dart';
import '../../../../core/widgets/paginacion_controles.dart';
import '../bloc/auditoria_cubit.dart';
import '../bloc/auditoria_state.dart';
import '../dialogs/entrada_auditoria_dialog.dart';
import '../widgets/auditoria_filtros_bar.dart';
import '../widgets/auditoria_table.dart';

/// Consulta de la bitácora de auditoría (solo lectura, RF-AUD-003).
class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuditoriaCubit>().recargar();
  }

  void _snack(String texto, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(texto), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuditoriaCubit, AuditoriaState>(
      listenWhen: (a, b) =>
          (b.mensajeExito != null && a.mensajeExito != b.mensajeExito) ||
          (b.mensajeError != null && a.mensajeError != b.mensajeError),
      listener: (context, s) {
        if (s.mensajeExito != null) {
          _snack(s.mensajeExito!, AppColors.statusSuccessText);
        } else if (s.mensajeError != null) {
          _snack(s.mensajeError!, AppColors.statusDangerText);
        }
      },
      builder: (context, state) {
        final cubit = context.read<AuditoriaCubit>();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EncabezadoSeccion(
                icono: Icons.manage_search_rounded,
                titulo: 'Auditoría',
                subtitulo: 'Bitácora inmutable de operaciones (RF-AUD-003)',
                acciones: [
                  BotonesExportar(
                    exportando: state.exportando,
                    onExportar: cubit.exportar,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AuditoriaFiltrosBar(
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

  Widget _contenido(AuditoriaState state, AuditoriaCubit cubit) {
    switch (state.status) {
      case AuditoriaStatus.inicial:
      case AuditoriaStatus.cargando:
        return AvisoPanel.cargando();
      case AuditoriaStatus.error:
        return AvisoPanel.error(
          titulo: 'Error al consultar la bitácora',
          detalle: state.error ?? '',
          onReintentar: cubit.recargar,
        );
      case AuditoriaStatus.cargado:
        final pagina = state.pagina!;
        if (pagina.items.isEmpty && pagina.pagina == 1) {
          return const AvisoPanel(
            icono: Icons.history_toggle_off_rounded,
            titulo: 'Sin registros',
            detalle: 'No hay eventos de auditoría para estos filtros.',
          );
        }
        return Column(
          children: [
            AuditoriaTable(
              entradas: pagina.items,
              onVer: (e) => EntradaAuditoriaDialog.show(context, e),
            ),
            const SizedBox(height: 8),
            PaginacionControles(
              pagina: pagina,
              sustantivo: 'registros',
              onPagina: cubit.irAPagina,
            ),
          ],
        );
    }
  }
}
