import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/download/guardar_archivo.dart';
import '../../../../core/network/mensaje_error.dart';
import '../../data/models/ocupacion_model.dart';
import '../../domain/reportes_operativos_repository.dart';
import 'ocupacion_state.dart';

/// Consulta y exportación del reporte de ocupación de espacios (US-REP-04).
class OcupacionCubit extends Cubit<OcupacionState> {
  static const String mensajeFiltroIncompleto =
      'Seleccione un periodo académico o un rango de fechas completo.';

  final ReportesOperativosRepository _repository;
  final GuardarArchivo _guardar;
  final DateTime Function() _ahora;

  OcupacionCubit({
    required ReportesOperativosRepository repository,
    GuardarArchivo guardar = guardarEnNavegador,
    DateTime Function()? ahora,
  }) : _repository = repository,
       _guardar = guardar,
       _ahora = ahora ?? DateTime.now,
       super(const OcupacionState());

  /// Carga los periodos del selector; un fallo no bloquea el rango de fechas.
  Future<void> cargarPeriodos() async {
    try {
      final periodos = await _repository.periodos();
      if (!isClosed) emit(state.copyWith(periodos: periodos));
    } catch (e) {
      if (!isClosed) emit(state.copyWith(mensajeError: mensajeDeError(e)));
    }
  }

  void cambiarFiltro(FiltroOcupacionModel filtro) =>
      emit(state.copyWith(filtro: filtro));

  /// Cambia la agregación (aula, bloque o sede) y vuelve a consultar.
  Future<void> agrupar(String agrupacion) async {
    emit(state.copyWith(filtro: state.filtro.copyWith(agrupacion: agrupacion)));
    if (state.filtro.esValido) await consultar();
  }

  Future<void> consultar() async {
    if (!state.filtro.esValido) {
      emit(state.copyWith(mensajeError: mensajeFiltroIncompleto));
      return;
    }
    emit(state.copyWith(status: OcupacionStatus.cargando, error: () => null));
    try {
      final r = await _repository.ocupacion(state.filtro);
      if (isClosed) return;
      emit(state.copyWith(status: OcupacionStatus.cargado, reporte: r));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: OcupacionStatus.error,
          error: () => mensajeDeError(e),
        ),
      );
    }
  }

  /// Descarga el reporte en `xlsx` o `pdf` con el filtro vigente (US-REP-02).
  Future<void> exportar(String formato) async {
    if (!state.filtro.esValido) {
      emit(state.copyWith(mensajeError: mensajeFiltroIncompleto));
      return;
    }
    if (state.exportando != null) return;
    emit(state.copyWith(exportando: () => formato));
    try {
      final archivo = await _repository.exportarOcupacion(
        state.filtro,
        formato,
      );
      _guardar(archivo, nombreExportacion('ocupacion', formato, _ahora()));
      if (isClosed) return;
      emit(
        state.copyWith(
          exportando: () => null,
          mensajeExito: 'Reporte exportado (${formato.toUpperCase()}).',
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(exportando: () => null, mensajeError: mensajeDeError(e)),
      );
    }
  }
}
