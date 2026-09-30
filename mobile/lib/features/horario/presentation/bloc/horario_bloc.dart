// horario_bloc.dart - BLoC de la vista semanal de Mi Horario (US-ACA-01..09, §9.1)
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_error.dart';
import '../../data/repositories/horario_repository_impl.dart';
import '../../domain/repositories/horario_repository.dart';
import 'horario_event.dart';
import 'horario_state.dart';

class HorarioBloc extends Bloc<HorarioEvent, HorarioState> {
  final HorarioRepository _repository;

  HorarioBloc({HorarioRepository? repository, DateTime? hoy})
      : _repository = repository ?? HorarioRepositoryImpl(),
        super(HorarioState.inicial(hoy ?? DateTime.now())) {
    on<CargarHorarioEvent>(_onCargar);
    on<CambiarDiaEvent>(_onCambiarDia);
    on<CambiarSemanaEvent>(_onCambiarSemana);
    on<RecargarHorarioEvent>(
        (_, emit) => _cargarSemana(emit, state.lunes, state.diaSeleccionado));
  }

  Future<void> _onCargar(
      CargarHorarioEvent event, Emitter<HorarioState> emit) async {
    final dia = HorarioState.diaLectivoDe(event.fecha ?? DateTime.now());
    emit(state.copyWith(docenteId: event.docenteId));
    await _cargarSemana(emit, HorarioState.lunesDe(dia), dia);
  }

  void _onCambiarDia(CambiarDiaEvent event, Emitter<HorarioState> emit) {
    final dia = DateTime(event.fecha.year, event.fecha.month, event.fecha.day);
    if (HorarioState.lunesDe(dia) == state.lunes) {
      emit(state.copyWith(diaSeleccionado: dia, error: state.error));
    } else {
      add(CargarHorarioEvent(fecha: dia, docenteId: state.docenteId));
    }
  }

  Future<void> _onCambiarSemana(
      CambiarSemanaEvent event, Emitter<HorarioState> emit) async {
    final lunes = DateTime(state.lunes.year, state.lunes.month,
        state.lunes.day + 7 * event.desplazamiento);
    final offset = state.diaSeleccionado.difference(state.lunes).inDays;
    await _cargarSemana(
        emit, lunes, DateTime(lunes.year, lunes.month, lunes.day + offset));
  }

  Future<void> _cargarSemana(
      Emitter<HorarioState> emit, DateTime lunes, DateTime dia) async {
    emit(state.copyWith(
      estado: EstadoCargaHorario.cargando,
      lunes: lunes,
      diaSeleccionado: dia,
      sesionesPorDia: const {},
    ));
    try {
      final semana = await _repository.obtenerSemana(
        lunes: lunes,
        docenteId: state.docenteId,
      );
      emit(state.copyWith(
          estado: EstadoCargaHorario.listo, sesionesPorDia: semana));
    } catch (e) {
      emit(state.copyWith(
        estado: EstadoCargaHorario.error,
        error: mensajeDeError(e,
            porDefecto: 'No se pudo cargar el horario. Inténtalo de nuevo.'),
      ));
    }
  }
}
