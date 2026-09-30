// justificaciones_lista_cubit.dart — Listado paginado de justificaciones propias
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/justificacion_repository.dart';
import '../../domain/models/catalogo_justificacion.dart';
import '../../domain/models/justificacion_exception.dart';
import 'justificaciones_lista_state.dart';

class JustificacionesListaCubit extends Cubit<JustificacionesListaState> {
  static const int limite = 20;

  final JustificacionRepository _repository;

  JustificacionesListaCubit(this._repository)
      : super(const JustificacionesListaState());

  /// Carga la primera página con el filtro de estado indicado (`null` = todas).
  Future<void> cargar({EstadoJustificacion? estado}) async {
    emit(JustificacionesListaState(carga: CargaLista.cargando, filtro: estado));
    await _primeraPagina();
  }

  /// Pull-to-refresh: conserva la lista visible mientras consulta.
  Future<void> refrescar() => _primeraPagina();

  Future<void> cargarMas() async {
    if (!state.hayMas || state.cargandoMas) return;
    emit(state.copyWith(cargandoMas: true));
    try {
      final pagina = await _repository.listar(
        estado: state.filtro?.codigo,
        pagina: state.items.length ~/ limite + 1,
        limite: limite,
      );
      emit(state.copyWith(
        items: [...state.items, ...pagina.items],
        total: pagina.total,
        cargandoMas: false,
      ));
    } on JustificacionException catch (e) {
      emit(state.copyWith(cargandoMas: false, error: e.mensaje));
    }
  }

  Future<void> _primeraPagina() async {
    try {
      final pagina = await _repository.listar(
        estado: state.filtro?.codigo,
        limite: limite,
      );
      emit(state.copyWith(
        carga: CargaLista.lista,
        items: pagina.items,
        total: pagina.total,
      ));
    } on JustificacionException catch (e) {
      final conDatos = state.carga == CargaLista.lista;
      emit(state.copyWith(
        carga: conDatos ? CargaLista.lista : CargaLista.error,
        error: e.mensaje,
      ));
    }
  }
}
