// horario_bloc.dart - BLoC para consulta y actualización del horario (US-ACA-01..09)
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/horario_repository.dart';
import '../../data/repositories/horario_repository_impl.dart';
import 'horario_event.dart';
import 'horario_state.dart';

class HorarioBloc extends Bloc<HorarioEvent, HorarioState> {
  final HorarioRepository _repository;

  HorarioBloc({HorarioRepository? repository})
      : _repository = repository ?? HorarioRepositoryImpl(),
        super(const HorarioInitial()) {
    on<CargarHorarioEvent>(_onCargarHorario);
    on<CambiarDiaEvent>(_onCambiarDia);
  }

  Future<void> _onCargarHorario(
    CargarHorarioEvent event,
    Emitter<HorarioState> emit,
  ) async {
    emit(const HorarioLoading());
    try {
      final fecha = event.fecha ?? DateTime.now();
      final sesiones = await _repository.obtenerHorario(
        docenteId: event.docenteId,
        fecha: fecha,
      );
      emit(HorarioLoaded(
        sesiones: sesiones,
        fechaSeleccionada: fecha,
        docenteId: event.docenteId,
      ));
    } catch (e) {
      emit(HorarioError('Error al cargar el horario: ${e.toString()}'));
    }
  }

  Future<void> _onCambiarDia(
    CambiarDiaEvent event,
    Emitter<HorarioState> emit,
  ) async {
    String? currentDocenteId;
    if (state is HorarioLoaded) {
      currentDocenteId = (state as HorarioLoaded).docenteId;
    }

    emit(const HorarioLoading());
    try {
      final sesiones = await _repository.obtenerHorario(
        docenteId: currentDocenteId,
        fecha: event.fecha,
      );
      emit(HorarioLoaded(
        sesiones: sesiones,
        fechaSeleccionada: event.fecha,
        docenteId: currentDocenteId,
      ));
    } catch (e) {
      emit(HorarioError('Error al cargar el horario: ${e.toString()}'));
    }
  }
}
