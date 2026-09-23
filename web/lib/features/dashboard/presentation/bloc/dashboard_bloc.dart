import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/admin_geo_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final AdminGeoRepository _geoRepo;

  DashboardBloc({AdminGeoRepository? geoRepo})
      : _geoRepo = geoRepo ?? AdminGeoRepository(),
        super(const DashboardState()) {
    on<DashboardCargarDatosRequested>(_onCargarDatos);
    on<DashboardCambiarNavIndexRequested>(_onCambiarNavIndex);
    on<DashboardCrearSedeRequested>(_onCrearSede);
    on<DashboardCrearBloqueRequested>(_onCrearBloque);
    on<DashboardCrearEspacioRequested>(_onCrearEspacio);
    on<DashboardEliminarEspacioRequested>(_onEliminarEspacio);
    on<DashboardLimpiarMensajesRequested>(_onLimpiarMensajes);
  }

  Future<void> _onCargarDatos(
    DashboardCargarDatosRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading, clearErrors: true));
    try {
      final results = await Future.wait([
        _geoRepo.listarSedes(),
        _geoRepo.listarBloques(),
        _geoRepo.listarEspacios(),
      ]);

      emit(state.copyWith(
        status: DashboardStatus.success,
        sedes: results[0] as List<AdminSede>,
        bloques: results[1] as List<AdminBloque>,
        espacios: results[2] as List<AdminEspacio>,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  void _onCambiarNavIndex(
    DashboardCambiarNavIndexRequested event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(selectedNavIndex: event.index));
  }

  Future<void> _onCrearSede(
    DashboardCrearSedeRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await _geoRepo.crearSede(
        codigo: event.codigo,
        nombre: event.nombre,
        direccion: event.direccion,
      );
      emit(state.copyWith(
        successMessage: 'Sede "${event.nombre}" creada con éxito.',
        clearErrors: true,
      ));
      add(const DashboardCargarDatosRequested());
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error al crear sede: ${e.toString().replaceFirst("Exception: ", "")}',
      ));
    }
  }

  Future<void> _onCrearBloque(
    DashboardCrearBloqueRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await _geoRepo.crearBloque(
        sedeId: event.sedeId,
        codigo: event.codigo,
        nombre: event.nombre,
        pisos: event.pisos,
      );
      emit(state.copyWith(
        successMessage: 'Bloque "${event.nombre}" creado con éxito.',
        clearErrors: true,
      ));
      add(const DashboardCargarDatosRequested());
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error al crear bloque: ${e.toString().replaceFirst("Exception: ", "")}',
      ));
    }
  }

  Future<void> _onCrearEspacio(
    DashboardCrearEspacioRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await _geoRepo.crearEspacio(
        sedeId: event.sedeId,
        bloqueId: event.bloqueId,
        piso: event.piso,
        codigo: event.codigo,
        nombre: event.nombre,
        capacidad: event.capacidad,
        tipo: event.tipo,
      );
      emit(state.copyWith(
        successMessage: 'Espacio "${event.codigo}" registrado exitosamente.',
        clearErrors: true,
      ));
      add(const DashboardCargarDatosRequested());
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error al crear espacio: ${e.toString().replaceFirst("Exception: ", "")}',
      ));
    }
  }

  Future<void> _onEliminarEspacio(
    DashboardEliminarEspacioRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await _geoRepo.eliminarEspacio(event.espacioId);
      emit(state.copyWith(
        successMessage: 'Espacio eliminado del registro cartográfico.',
        clearErrors: true,
      ));
      add(const DashboardCargarDatosRequested());
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error al eliminar espacio: ${e.toString().replaceFirst("Exception: ", "")}',
      ));
    }
  }

  void _onLimpiarMensajes(
    DashboardLimpiarMensajesRequested event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(clearErrors: true));
  }
}
