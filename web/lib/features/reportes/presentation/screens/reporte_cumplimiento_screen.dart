import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/aviso_panel.dart';
import '../../../../core/widgets/botones_exportar.dart';
import '../../../../core/widgets/encabezado_seccion.dart';
import '../bloc/catalogo_reporte_cubit.dart';
import '../bloc/reporte_cumplimiento_cubit.dart';
import '../bloc/reporte_cumplimiento_state.dart';
import '../widgets/reporte_filtros_bar.dart';
import '../widgets/reporte_indicadores.dart';
import '../widgets/reporte_tabla.dart';

/// Reporte de cumplimiento docente con indicadores y exportación (EP-08).
class ReporteCumplimientoScreen extends StatefulWidget {
  /// true si el usuario tiene `reporte:exportar`.
  final bool puedeExportar;

  const ReporteCumplimientoScreen({super.key, this.puedeExportar = false});

  @override
  State<ReporteCumplimientoScreen> createState() =>
      _ReporteCumplimientoScreenState();
}

class _ReporteCumplimientoScreenState extends State<ReporteCumplimientoScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CatalogoReporteCubit>().cargar();
  }

  void _snack(String texto, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(texto), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReporteCumplimientoCubit, ReporteCumplimientoState>(
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
        final cubit = context.read<ReporteCumplimientoCubit>();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EncabezadoSeccion(
                icono: Icons.insights_rounded,
                titulo: 'Reportes de cumplimiento',
                subtitulo: 'Horas dictadas, tardanzas y ausencias por docente',
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
              ReporteFiltrosBar(
                filtro: state.filtro,
                consultando: state.status == ReporteStatus.cargando,
                onCambio: cubit.cambiarFiltro,
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

  Widget _contenido(
    ReporteCumplimientoState state,
    ReporteCumplimientoCubit cubit,
  ) {
    switch (state.status) {
      case ReporteStatus.inicial:
        return const AvisoPanel(
          icono: Icons.query_stats_rounded,
          titulo: 'Configure el reporte',
          detalle:
              'Elija un periodo académico o un rango de fechas y pulse '
              '"Consultar".',
        );
      case ReporteStatus.cargando:
        return AvisoPanel.cargando();
      case ReporteStatus.error:
        return AvisoPanel.error(
          titulo: 'Error al generar el reporte',
          detalle: state.error ?? '',
          onReintentar: cubit.consultar,
        );
      case ReporteStatus.cargado:
        final r = state.reporte!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReporteIndicadores(reporte: r),
            const SizedBox(height: 16),
            if (r.docentes.isEmpty)
              const AvisoPanel(
                icono: Icons.person_search_rounded,
                titulo: 'Sin sesiones en el alcance',
                detalle: 'No hay docentes con sesiones para estos filtros.',
              )
            else
              ReporteTabla(docentes: r.docentes, totales: r.totales),
            const SizedBox(height: 8),
            Text(
              'Generado: ${Formatos.fechaHora(r.generadoEn)}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        );
    }
  }
}
