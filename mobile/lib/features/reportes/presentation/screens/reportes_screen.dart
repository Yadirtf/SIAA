// reportes_screen.dart — Reporte de cumplimiento docente en móvil (RF-REP-001).
// La exportación a XLSX/PDF (reporte:exportar) se hace desde la consola web.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/estado_vista.dart';
import '../../data/reportes_remote_datasource.dart';
import '../cubit/reportes_cubit.dart';
import '../widgets/fila_docente_tile.dart';
import '../widgets/filtro_reporte_card.dart';
import '../widgets/resumen_cumplimiento_card.dart';

class ReportesScreen extends StatelessWidget {
  final ReportesRemoteDataSource? remote;

  const ReportesScreen({super.key, this.remote});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportesCubit(remote: remote)..iniciar(),
      child: BlocBuilder<ReportesCubit, ReportesState>(
        builder: (context, state) {
          final cubit = context.read<ReportesCubit>();
          return Column(
            children: [
              FiltroReporteCard(
                periodos: state.periodos,
                periodo: state.periodo,
                desde: state.desde,
                hasta: state.hasta,
                onPeriodo: cubit.elegirPeriodo,
                onRango: cubit.elegirRango,
              ),
              Expanded(child: _cuerpo(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _cuerpo(BuildContext context, ReportesState state) {
    final cubit = context.read<ReportesCubit>();
    switch (state.estado) {
      case EstadoReporte.cargando:
        return const Center(child: CircularProgressIndicator());
      case EstadoReporte.error:
        return EstadoError(
          mensaje: state.error ?? 'No se pudo generar el reporte.',
          onReintentar: cubit.consultar,
        );
      case EstadoReporte.listo:
        final reporte = state.reporte!;
        return RefreshIndicator(
          onRefresh: cubit.consultar,
          child: ListView(
            children: [
              ResumenCumplimientoCard(reporte: reporte),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Para exportar a Excel o PDF usa la consola web SIAA.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
              if (reporte.docentes.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: EstadoVacio(
                    icono: Icons.bar_chart_rounded,
                    mensaje: 'No hay sesiones en el periodo seleccionado',
                  ),
                )
              else ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Docentes (menor cumplimiento primero)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                for (final f in reporte.docentes) FilaDocenteTile(fila: f),
              ],
            ],
          ),
        );
    }
  }
}
