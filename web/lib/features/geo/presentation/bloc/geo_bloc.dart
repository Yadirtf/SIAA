import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/geo_repository.dart';
import 'geo_event.dart';
import 'geo_state.dart';

class GeoBloc extends Bloc<GeoEvent, GeoState> {
  final GeoRepository _repository;

  GeoBloc({required GeoRepository repository})
      : _repository = repository,
        super(const GeoInitial()) {
    on<LoadGeoDataEvent>(_onLoadGeoData);
    on<CreateSedeEvent>(_onCreateSede);
    on<CreateBloqueEvent>(_onCreateBloque);
    on<CreateEspacioEvent>(_onCreateEspacio);
    on<DeleteEspacioEvent>(_onDeleteEspacio);
    on<LoadSolapamientosEvent>(_onLoadSolapamientos);
  }

  Future<void> _onLoadGeoData(
    LoadGeoDataEvent event,
    Emitter<GeoState> emit,
  ) async {
    emit(const GeoLoading());
    try {
      final sedes = await _repository.getSedes();
      final selectedSede = event.sedeId ?? (sedes.isNotEmpty ? sedes.first.id : null);
      final bloques = await _repository.getBloques(sedeId: selectedSede);
      final espacios = await _repository.getEspacios(
        sedeId: selectedSede,
        bloqueId: event.bloqueId,
      );

      emit(GeoLoaded(
        sedes: sedes,
        bloques: bloques,
        espacios: espacios,
        selectedSedeId: selectedSede,
        selectedBloqueId: event.bloqueId,
      ));
    } catch (e) {
      emit(GeoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateSede(
    CreateSedeEvent event,
    Emitter<GeoState> emit,
  ) async {
    try {
      await _repository.createSede(
        codigo: event.codigo,
        nombre: event.nombre,
        direccion: event.direccion,
      );
      add(const LoadGeoDataEvent());
    } catch (e) {
      emit(GeoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateBloque(
    CreateBloqueEvent event,
    Emitter<GeoState> emit,
  ) async {
    try {
      await _repository.createBloque(
        sedeId: event.sedeId,
        codigo: event.codigo,
        nombre: event.nombre,
        pisos: event.pisos,
      );
      add(LoadGeoDataEvent(sedeId: event.sedeId));
    } catch (e) {
      emit(GeoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateEspacio(
    CreateEspacioEvent event,
    Emitter<GeoState> emit,
  ) async {
    try {
      await _repository.createEspacio(
        sedeId: event.sedeId,
        bloqueId: event.bloqueId,
        piso: event.piso,
        codigo: event.codigo,
        nombre: event.nombre,
        capacidad: event.capacidad,
        tipo: event.tipo,
        facultadResponsable: event.facultadResponsable,
      );
      add(LoadGeoDataEvent(sedeId: event.sedeId, bloqueId: event.bloqueId));
    } catch (e) {
      emit(GeoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteEspacio(
    DeleteEspacioEvent event,
    Emitter<GeoState> emit,
  ) async {
    try {
      await _repository.deleteEspacio(event.id);
      if (state is GeoLoaded) {
        final current = state as GeoLoaded;
        add(LoadGeoDataEvent(
          sedeId: current.selectedSedeId,
          bloqueId: current.selectedBloqueId,
        ));
      } else {
        add(const LoadGeoDataEvent());
      }
    } catch (e) {
      emit(GeoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadSolapamientos(
    LoadSolapamientosEvent event,
    Emitter<GeoState> emit,
  ) async {
    try {
      final solapamientos = await _repository.getSolapamientos(sedeId: event.sedeId);
      if (state is GeoLoaded) {
        emit((state as GeoLoaded).copyWith(solapamientos: solapamientos));
      }
    } catch (e) {
      emit(GeoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }
}
