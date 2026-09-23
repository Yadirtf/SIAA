import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../geo_editor/data/espacio_repository.dart';
import 'home_bloc_creation_handlers.dart';
import 'home_event.dart';
import 'home_state.dart';

/// BLoC que centraliza toda la lógica de negocio, datos y llamadas a MongoDB
/// para la jerarquía física y módulos de SIAA Móvil (US-GEO-01).
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final EspacioRepository repository;

  HomeBloc({EspacioRepository? repository})
      : repository = repository ?? EspacioRepository(),
        super(const HomeState()) {
    on<CargarSedesRequested>(_onCargarSedesRequested);
    on<SeleccionarSedeRequested>(_onSeleccionarSedeRequested);
    on<SeleccionarBloqueRequested>(_onSeleccionarBloqueRequested);
    on<CrearSedeRequested>(onCrearSedeRequested);
    on<CrearBloqueRequested>(onCrearBloqueRequested);
    on<CrearEspacioRequested>(onCrearEspacioRequested);
    on<RefrescarEspaciosRequested>(_onRefrescarEspaciosRequested);
    on<LimpiarMensajesHomeRequested>(_onLimpiarMensajesHomeRequested);
  }

  Future<void> _onCargarSedesRequested(
    CargarSedesRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(cargandoSedes: true, clearError: true));
    try {
      final sedes = await repository.obtenerSedes();
      if (sedes.isNotEmpty) {
        final primera = sedes.first;
        emit(state.copyWith(
          sedes: sedes,
          sedeSeleccionada: primera,
          cargandoSedes: false,
          cargandoBloques: true,
        ));
        final bloques = await repository.obtenerBloques(sedeId: primera.id);
        if (bloques.isNotEmpty) {
          final primerBloque = bloques.first;
          emit(state.copyWith(
            bloques: bloques,
            bloqueSeleccionado: primerBloque,
            cargandoBloques: false,
            cargandoEspacios: true,
          ));
          final espacios = await repository.obtenerEspacios(
            sedeId: primera.id,
            bloqueId: primerBloque.id,
          );
          emit(state.copyWith(espacios: espacios, cargandoEspacios: false));
        } else {
          emit(state.copyWith(
            bloques: const [],
            clearBloqueSeleccionado: true,
            espacios: const [],
            cargandoBloques: false,
            cargandoEspacios: false,
          ));
        }
      } else {
        emit(state.copyWith(
          sedes: const [],
          clearSedeSeleccionada: true,
          bloques: const [],
          clearBloqueSeleccionado: true,
          espacios: const [],
          cargandoSedes: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        cargandoSedes: false,
        cargandoBloques: false,
        cargandoEspacios: false,
        errorMessage: 'Error al consultar sedes: $e',
      ));
    }
  }

  Future<void> _onSeleccionarSedeRequested(
    SeleccionarSedeRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(
      sedeSeleccionada: event.sede,
      cargandoBloques: true,
      bloques: const [],
      clearBloqueSeleccionado: true,
      espacios: const [],
    ));
    try {
      final bloques = await repository.obtenerBloques(sedeId: event.sede.id);
      if (bloques.isNotEmpty) {
        final primerBloque = bloques.first;
        emit(state.copyWith(
          bloques: bloques,
          bloqueSeleccionado: primerBloque,
          cargandoBloques: false,
          cargandoEspacios: true,
        ));
        final espacios = await repository.obtenerEspacios(
          sedeId: event.sede.id,
          bloqueId: primerBloque.id,
        );
        emit(state.copyWith(espacios: espacios, cargandoEspacios: false));
      } else {
        emit(state.copyWith(
          bloques: const [],
          clearBloqueSeleccionado: true,
          espacios: const [],
          cargandoBloques: false,
          cargandoEspacios: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        cargandoBloques: false,
        cargandoEspacios: false,
        errorMessage: 'Error al consultar bloques: $e',
      ));
    }
  }

  Future<void> _onSeleccionarBloqueRequested(
    SeleccionarBloqueRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (state.sedeSeleccionada == null) return;
    emit(state.copyWith(
      bloqueSeleccionado: event.bloque,
      cargandoEspacios: true,
      espacios: const [],
    ));
    try {
      final espacios = await repository.obtenerEspacios(
        sedeId: state.sedeSeleccionada!.id,
        bloqueId: event.bloque.id,
      );
      emit(state.copyWith(espacios: espacios, cargandoEspacios: false));
    } catch (e) {
      emit(state.copyWith(
        cargandoEspacios: false,
        errorMessage: 'Error al consultar aulas: $e',
      ));
    }
  }

  Future<void> _onRefrescarEspaciosRequested(
    RefrescarEspaciosRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (state.sedeSeleccionada == null || state.bloqueSeleccionado == null) return;
    try {
      final espacios = await repository.obtenerEspacios(
        sedeId: state.sedeSeleccionada!.id,
        bloqueId: state.bloqueSeleccionado!.id,
      );
      emit(state.copyWith(espacios: espacios));
    } catch (_) {}
  }

  void _onLimpiarMensajesHomeRequested(
    LimpiarMensajesHomeRequested event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(clearError: true, clearSuccess: true, clearUltimoEspacio: true));
  }
}
