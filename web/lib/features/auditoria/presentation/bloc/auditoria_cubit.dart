import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/download/guardar_archivo.dart';
import '../../../../core/network/mensaje_error.dart';
import '../../data/models/filtro_auditoria_model.dart';
import '../../domain/auditoria_repository.dart';
import 'auditoria_state.dart';

/// Consulta paginada y exportación de la bitácora de auditoría.
class AuditoriaCubit extends Cubit<AuditoriaState> {
  final AuditoriaRepository _repository;
  final GuardarArchivo _guardar;
  final DateTime Function() _ahora;

  AuditoriaCubit({
    required AuditoriaRepository repository,
    GuardarArchivo guardar = guardarEnNavegador,
    DateTime Function()? ahora,
  }) : _repository = repository,
       _guardar = guardar,
       _ahora = ahora ?? DateTime.now,
       super(const AuditoriaState());

  Future<void> cargar([FiltroAuditoriaModel? filtro]) async {
    final f = filtro ?? state.filtro;
    emit(state.copyWith(status: AuditoriaStatus.cargando, filtro: f));
    try {
      final pagina = await _repository.consultar(f);
      if (isClosed) return;
      emit(state.copyWith(status: AuditoriaStatus.cargado, pagina: pagina));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(status: AuditoriaStatus.error, error: mensajeDeError(e)),
      );
    }
  }

  Future<void> recargar() => cargar(state.filtro);

  Future<void> irAPagina(int pagina) =>
      cargar(state.filtro.copyWith(pagina: pagina));

  /// Descarga la bitácora filtrada en `xlsx` o `pdf`.
  Future<void> exportar(String formato) async {
    if (state.exportando != null) return;
    emit(state.copyWith(exportando: () => formato, error: state.error));
    try {
      final archivo = await _repository.exportar(state.filtro, formato);
      _guardar(archivo, nombreExportacion('auditoria', formato, _ahora()));
      if (isClosed) return;
      emit(
        state.copyWith(
          exportando: () => null,
          error: state.error,
          mensajeExito: 'Bitácora exportada (${formato.toUpperCase()}).',
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
