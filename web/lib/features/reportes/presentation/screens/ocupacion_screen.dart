import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/aviso_panel.dart';
import '../../../../core/widgets/botones_exportar.dart';
import '../../../../core/widgets/encabezado_seccion.dart';
import '../bloc/ocupacion_cubit.dart';
import '../bloc/ocupacion_state.dart';
import '../widgets/ocupacion_filtros.dart';
import '../widgets/ocupacion_tabla.dart';

/// Reporte de ocupación de espacios (US-REP-04). Requiere un [OcupacionCubit]
/// en el contexto.
class OcupacionScreen extends StatefulWidget {
  /// true si el usuario tiene `reporte:exportar`.
  final bool puedeExportar;

  const OcupacionScreen({super.key, this.puedeExportar = false});

  @override
  State<OcupacionScreen> createState() => _OcupacionScreenState();
}

class _OcupacionScreenState extends State<OcupacionScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OcupacionCubit>().cargarPeriodos();
  }

  void _snack(String texto, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(texto), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OcupacionCubit, OcupacionState>(
      listenWhen: (a, b) => b.mensajeExito != null || b.mensajeError != null,
      listener: (context, s) {
        if (s.mensajeExito != null) {
          _snack(s.mensajeExito!, AppColors.statusSuccessText);
        } else if (s.mensajeError != null) {
          _snack(s.mensajeError!, AppColors.statusDangerText);
        }
      },
      builder: (context, state) {
        final cubit = context.read<OcupacionCubit>();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EncabezadoSeccion(
                icono: Icons.meeting_room_outlined,
                titulo: 'Ocupación de espacios',
                subtitulo: 'Horas programadas frente a uso confirmado',
                acciones: [
                  if (widget.puedeExportar)
                    BotonesExportar(
                      exportando: state.exportando,
                      habilitado: state.filtro.esValido,
                      onExportar: cubit.exportar,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              OcupacionFiltros(
                filtro: state.filtro,
                periodos: state.periodos,
                consultando: state.status == OcupacionStatus.cargando,
                onCambio: cubit.cambiarFiltro,
                onAgrupar: cubit.agrupar,
                onConsultar: cubit.consultar,
              ),
              const SizedBox(height: 16),
              _contenido(state, cubit),
            ],
          ),
        );
      },
    );
  }

  Widget _contenido(OcupacionState state, OcupacionCubit cubit) {
    switch (state.status) {
      case OcupacionStatus.inicial:
        return const AvisoPanel(
          icono: Icons.query_stats_rounded,
          titulo: 'Configure el reporte',
          detalle:
              'Elija un periodo académico o un rango de fechas y pulse '
              '"Consultar".',
        );
      case OcupacionStatus.cargando:
        return AvisoPanel.cargando();
      case OcupacionStatus.error:
        return AvisoPanel.error(
          titulo: 'Error al generar el reporte',
          detalle: state.error ?? '',
          onReintentar: cubit.consultar,
        );
      case OcupacionStatus.cargado:
        final r = state.reporte!;
        if (r.filas.isEmpty) {
          return const AvisoPanel(
            icono: Icons.meeting_room_outlined,
            titulo: 'Sin sesiones en el alcance',
            detalle: 'No hay sesiones terminadas para estos filtros.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OcupacionTabla(reporte: r),
            const SizedBox(height: 8),
            Text(
              'Utilización = horas con entrada válida del docente / horas '
              'programadas. Generado: ${Formatos.fechaHora(r.generadoEn)}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        );
    }
  }
}
