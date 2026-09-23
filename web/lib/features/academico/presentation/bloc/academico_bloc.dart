import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/academico_repository.dart';
import 'academico_event.dart';
import 'academico_state.dart';

class AcademicoBloc extends Bloc<AcademicoEvent, AcademicoState> {
  final AcademicoRepository _repository;

  AcademicoBloc({required AcademicoRepository repository})
      : _repository = repository,
        super(const AcademicoInitial()) {
    on<LoadAcademicoDataEvent>(_onLoadData);
    on<CreatePeriodoEvent>(_onCreatePeriodo);
    on<CreateFacultadEvent>(_onCreateFacultad);
    on<DeleteFacultadEvent>(_onDeleteFacultad);
    on<CreateProgramaEvent>(_onCreatePrograma);
    on<DeleteProgramaEvent>(_onDeletePrograma);
    on<CreateAsignaturaEvent>(_onCreateAsignatura);
    on<DeleteAsignaturaEvent>(_onDeleteAsignatura);
    on<CreateGrupoEvent>(_onCreateGrupo);
    on<CreateAsignacionEvent>(_onCreateAsignacion);
    on<DeleteAsignacionEvent>(_onDeleteAsignacion);
    on<CreateExcepcionEvent>(_onCreateExcepcion);
    on<DeleteExcepcionEvent>(_onDeleteExcepcion);
  }

  Future<void> _onLoadData(
    LoadAcademicoDataEvent event,
    Emitter<AcademicoState> emit,
  ) async {
    emit(const AcademicoLoading());
    try {
      final periodos = await _repository.getPeriodos();
      final facultades = await _repository.getFacultades();
      final programas = await _repository.getProgramas();
      final asignaturas = await _repository.getAsignaturas();
      final grupos = await _repository.getGrupos();
      final asignaciones = await _repository.getAsignaciones();
      final excepciones = await _repository.getExcepciones();

      emit(AcademicoLoaded(
        periodos: periodos,
        facultades: facultades,
        programas: programas,
        asignaturas: asignaturas,
        grupos: grupos,
        asignaciones: asignaciones,
        excepciones: excepciones,
      ));
    } catch (e) {
      emit(AcademicoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreatePeriodo(CreatePeriodoEvent event, Emitter<AcademicoState> emit) async {
    try {
      await _repository.createPeriodo(
        codigo: event.codigo,
        nombre: event.nombre,
        fechaInicio: event.fechaInicio,
        fechaFin: event.fechaFin,
        estado: event.estado,
      );
      add(const LoadAcademicoDataEvent());
    } catch (e) {
      emit(AcademicoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateFacultad(CreateFacultadEvent event, Emitter<AcademicoState> emit) async {
    try {
      await _repository.createFacultad(codigo: event.codigo, nombre: event.nombre, sedeId: event.sedeId);
      add(const LoadAcademicoDataEvent());
    } catch (e) {
      emit(AcademicoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteFacultad(DeleteFacultadEvent event, Emitter<AcademicoState> emit) async {
    try {
      await _repository.deleteFacultad(event.id);
      add(const LoadAcademicoDataEvent());
    } catch (e) {
      emit(AcademicoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreatePrograma(CreateProgramaEvent event, Emitter<AcademicoState> emit) async {
    try {
      await _repository.createPrograma(codigo: event.codigo, nombre: event.nombre, facultadId: event.facultadId);
      add(const LoadAcademicoDataEvent());
    } catch (e) {
      emit(AcademicoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeletePrograma(DeleteProgramaEvent event, Emitter<AcademicoState> emit) async {
    try {
      await _repository.deletePrograma(event.id);
      add(const LoadAcademicoDataEvent());
    } catch (e) {
      emit(AcademicoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateAsignatura(CreateAsignaturaEvent event, Emitter<AcademicoState> emit) async {
    try {
      await _repository.createAsignatura(
        codigo: event.codigo,
        nombre: event.nombre,
        programaId: event.programaId,
        creditos: event.creditos,
      );
      add(const LoadAcademicoDataEvent());
    } catch (e) {
      emit(AcademicoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteAsignatura(DeleteAsignaturaEvent event, Emitter<AcademicoState> emit) async {
    try {
      await _repository.deleteAsignatura(event.id);
      add(const LoadAcademicoDataEvent());
    } catch (e) {
      emit(AcademicoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateGrupo(CreateGrupoEvent event, Emitter<AcademicoState> emit) async {
    try {
      await _repository.createGrupo(
        numero: event.numero,
        asignaturaId: event.asignaturaId,
        periodoId: event.periodoId,
        cupo: event.cupo,
      );
      add(const LoadAcademicoDataEvent());
    } catch (e) {
      emit(AcademicoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateAsignacion(CreateAsignacionEvent event, Emitter<AcademicoState> emit) async {
    try {
      await _repository.createAsignacion(event.body);
      add(const LoadAcademicoDataEvent());
    } catch (e) {
      emit(AcademicoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteAsignacion(DeleteAsignacionEvent event, Emitter<AcademicoState> emit) async {
    try {
      await _repository.deleteAsignacion(event.id);
      add(const LoadAcademicoDataEvent());
    } catch (e) {
      emit(AcademicoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateExcepcion(CreateExcepcionEvent event, Emitter<AcademicoState> emit) async {
    try {
      await _repository.createExcepcion(
        nombre: event.nombre,
        tipo: event.tipo,
        ambito: event.ambito,
        fechaInicio: event.fechaInicio,
        fechaFin: event.fechaFin,
      );
      add(const LoadAcademicoDataEvent());
    } catch (e) {
      emit(AcademicoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteExcepcion(DeleteExcepcionEvent event, Emitter<AcademicoState> emit) async {
    try {
      await _repository.deleteExcepcion(event.id);
      add(const LoadAcademicoDataEvent());
    } catch (e) {
      emit(AcademicoError(e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '')));
    }
  }
}
