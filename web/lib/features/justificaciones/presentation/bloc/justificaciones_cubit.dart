import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/mensaje_error.dart';
import '../../data/models/justificaciones_filtro.dart';
import '../../domain/justificaciones_repository.dart';
import 'justificaciones_state.dart';

/// Bandeja paginada de justificaciones con resolución de nombres de docentes.
class JustificacionesCubit extends Cubit<JustificacionesState> {
  final JustificacionesRepository _repository;

  JustificacionesCubit({required JustificacionesRepository repository})
    : _repository = repository,
      super(const JustificacionesState());

  Future<void> cargar([JustificacionesFiltro? filtro]) async {
    final f = filtro ?? state.filtro;
    emit(state.copyWith(status: JustificacionesStatus.cargando, filtro: f));
    try {
      final pagina = await _repository.listar(f);
      if (isClosed) return;
      emit(
        state.copyWith(status: JustificacionesStatus.cargado, pagina: pagina),
      );
      await _resolverNombres(pagina.items.map((j) => j.docenteId));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: JustificacionesStatus.error,
          error: mensajeDeError(e),
        ),
      );
    }
  }

  Future<void> recargar() => cargar(state.filtro);

  Future<void> irAPagina(int pagina) =>
      cargar(state.filtro.copyWith(pagina: pagina));

  /// Consulta los nombres aún no conocidos; los fallos (p. ej. 403 en
  /// /usuarios) se ignoran y la tabla sigue mostrando el id.
  Future<void> _resolverNombres(Iterable<String> ids) async {
    final pendientes = ids
        .where((id) => id.isNotEmpty && !state.nombres.containsKey(id))
        .toSet();
    if (pendientes.isEmpty) return;
    final resueltos = <String, String>{};
    await Future.wait(
      pendientes.map((id) async {
        try {
          final nombre = await _repository.nombreUsuario(id);
          if (nombre != null && nombre.isNotEmpty) resueltos[id] = nombre;
        } catch (_) {}
      }),
    );
    if (resueltos.isEmpty || isClosed) return;
    emit(state.copyWith(nombres: {...state.nombres, ...resueltos}));
  }
}
