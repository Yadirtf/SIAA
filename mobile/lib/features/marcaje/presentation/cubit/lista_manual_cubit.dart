// lista_manual_cubit.dart — Carga el grupo, marca presentes y envía la lista manual (US-MAR-14).
// Las filas bloqueadas ya tienen un registro válido que el servidor conserva (AC-04).
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../data/datasources/marcaje_grupal_remote_datasource.dart';
import 'lista_manual_state.dart';

class ListaManualCubit extends Cubit<ListaManualState> {
  final String sesionId;
  final MarcajeGrupalRemoteDataSource _remote;

  ListaManualCubit({
    required this.sesionId,
    MarcajeGrupalRemoteDataSource? remote,
  })  : _remote = remote ?? MarcajeGrupalRemoteDataSource(),
        super(const ListaManualState());

  Future<void> cargar() async {
    emit(state.copyWith(carga: CargaListaManual.cargando));
    try {
      final estudiantes = await _remote.consultarLista(sesionId);
      if (isClosed) return;
      emit(state.copyWith(
        carga: CargaListaManual.lista,
        estudiantes: estudiantes,
        presentes: {
          for (final e in estudiantes)
            if (!e.bloqueado) e.id: state.presente(e.id),
        },
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
          carga: CargaListaManual.error, error: mensajeDeError(e)));
    }
  }

  void cambiarPresente(String estudianteId, bool presente) {
    final bloqueado =
        state.estudiantes.any((e) => e.id == estudianteId && e.bloqueado);
    if (bloqueado || state.enviando) return;
    emit(state
        .copyWith(presentes: {...state.presentes, estudianteId: presente}));
  }

  void marcarTodos(bool presente) {
    if (state.enviando) return;
    emit(state.copyWith(presentes: {
      for (final e in state.estudiantes)
        if (!e.bloqueado) e.id: presente,
    }));
  }

  void cambiarMotivo(String motivo) {
    emit(state.copyWith(
      motivo: motivo,
      motivoFaltante: state.motivoFaltante && motivo.trim().isEmpty,
    ));
  }

  Future<void> enviar() async {
    if (!state.puedeEnviar) return;
    final motivo = state.motivo.trim();
    if (motivo.isEmpty) {
      emit(state.copyWith(motivoFaltante: true));
      return;
    }
    emit(state.copyWith(enviando: true, motivoFaltante: false));
    try {
      final resultado = await _remote.registrarLista(
        sesionId: sesionId,
        motivo: motivo,
        // Se envía el grupo completo: los bloqueados cuentan como "conservados".
        presentes: {
          for (final e in state.estudiantes)
            e.id: e.bloqueado || state.presente(e.id),
        },
      );
      if (isClosed) return;
      emit(state.copyWith(enviando: false, resultado: resultado));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(enviando: false, error: mensajeDeError(e)));
    }
  }
}
