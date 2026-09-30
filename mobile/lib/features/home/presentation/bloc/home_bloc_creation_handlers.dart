import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

extension HomeBlocCreationHandlers on HomeBloc {
  Future<void> onCrearSedeRequested(
    CrearSedeRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(cargandoSedes: true, clearError: true));
    try {
      final nueva = await repository.crearSede(
        codigo: event.codigo,
        nombre: event.nombre,
        direccion: event.direccion,
      );
      final sedes = await repository.obtenerSedes();
      final sedeEnLista = sedes.firstWhere(
        (s) => s.id == nueva.id,
        orElse: () => nueva,
      );
      emit(state.copyWith(
        sedes: sedes,
        sedeSeleccionada: sedeEnLista,
        cargandoSedes: false,
        successMessage: 'Sede "${nueva.nombre}" registrada con éxito.',
      ));
      add(SeleccionarSedeRequested(sedeEnLista));
    } catch (e) {
      emit(state.copyWith(
        cargandoSedes: false,
        errorMessage: 'Error al crear sede: $e',
      ));
    }
  }

  Future<void> onCrearBloqueRequested(
    CrearBloqueRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(cargandoBloques: true, clearError: true));
    try {
      final nuevo = await repository.crearBloque(
        sedeId: event.sedeId,
        codigo: event.codigo,
        nombre: event.nombre,
        pisos: event.pisos,
      );
      final bloques = await repository.obtenerBloques(sedeId: event.sedeId);
      final bloqueEnLista = bloques.firstWhere(
        (b) => b.id == nuevo.id,
        orElse: () => nuevo,
      );
      emit(state.copyWith(
        bloques: bloques,
        bloqueSeleccionado: bloqueEnLista,
        cargandoBloques: false,
        successMessage: 'Bloque "${nuevo.nombre}" registrado con éxito.',
      ));
      add(SeleccionarBloqueRequested(bloqueEnLista));
    } catch (e) {
      emit(state.copyWith(
        cargandoBloques: false,
        errorMessage: 'Error al crear bloque: $e',
      ));
    }
  }

  Future<void> onCrearEspacioRequested(
    CrearEspacioRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(cargandoEspacios: true, clearError: true));
    try {
      final nuevo = await repository.crearEspacio(
        sedeId: event.sedeId,
        bloqueId: event.bloqueId,
        piso: event.piso,
        codigo: event.codigo,
        nombre: event.nombre,
        capacidad: event.capacidad,
        tipo: event.tipo,
      );
      final espacios = await repository.obtenerEspacios(
        sedeId: event.sedeId,
        bloqueId: event.bloqueId,
      );
      emit(state.copyWith(
        espacios: espacios,
        cargandoEspacios: false,
        ultimoEspacioCreado: nuevo,
        successMessage: 'Aula "${nuevo.nombre}" creada con éxito en MongoDB.',
      ));
    } catch (e) {
      emit(state.copyWith(
        cargandoEspacios: false,
        errorMessage: 'Error al crear aula: $e',
      ));
    }
  }
}
