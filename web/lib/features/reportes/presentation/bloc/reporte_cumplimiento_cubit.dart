import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/download/guardar_archivo.dart';
import '../../../../core/network/mensaje_error.dart';
import '../../data/models/filtro_reporte_model.dart';
import '../../domain/reportes_repository.dart';
import 'reporte_cumplimiento_state.dart';

/// Consulta y exportación del reporte de cumplimiento docente.
class ReporteCumplimientoCubit extends Cubit<ReporteCumplimientoState> {
  static const String mensajeFiltroIncompleto =
      'Seleccione un periodo académico o un rango de fechas completo.';

  final ReportesRepository _repository;
  final GuardarArchivo _guardar;
  final DateTime Function() _ahora;

  ReporteCumplimientoCubit({
    required ReportesRepository repository,
    GuardarArchivo guardar = guardarEnNavegador,
    DateTime Function()? ahora,
  }) : _repository = repository,
       _guardar = guardar,
       _ahora = ahora ?? DateTime.now,
       super(const ReporteCumplimientoState());

  /// Actualiza los criterios sin consultar.
  void cambiarFiltro(FiltroReporteModel filtro) =>
      emit(state.copyWith(filtro: filtro, error: state.error));

  Future<void> consultar() async {
    final f = state.filtro;
    if (!f.esValido) {
      emit(
        state.copyWith(
          error: state.error,
          mensajeError: mensajeFiltroIncompleto,
        ),
      );
      return;
    }
    emit(state.copyWith(status: ReporteStatus.cargando));
    try {
      final reporte = await _repository.cumplimiento(f);
      if (isClosed) return;
      emit(state.copyWith(status: ReporteStatus.cargado, reporte: reporte));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(status: ReporteStatus.error, error: mensajeDeError(e)),
      );
    }
  }

  /// Descarga el reporte en `xlsx` o `pdf` con el filtro vigente.
  Future<void> exportar(String formato) async {
    final f = state.filtro;
    if (!f.esValido) {
      emit(
        state.copyWith(
          error: state.error,
          mensajeError: mensajeFiltroIncompleto,
        ),
      );
      return;
    }
    if (state.exportando != null) return;
    emit(state.copyWith(exportando: () => formato, error: state.error));
    try {
      final archivo = await _repository.exportar(f, formato);
      final nombre = nombreExportacion('cumplimiento', formato, _ahora());
      _guardar(archivo, nombre);
      if (isClosed) return;
      emit(
        state.copyWith(
          exportando: () => null,
          error: state.error,
          mensajeExito: 'Reporte exportado (${formato.toUpperCase()}).',
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          exportando: () => null,
          error: state.error,
          mensajeError: mensajeDeError(e),
        ),
      );
    }
  }
}
