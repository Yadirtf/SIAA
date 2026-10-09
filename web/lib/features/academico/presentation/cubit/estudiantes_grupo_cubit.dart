import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/mensaje_error.dart';
import '../../data/estudiantes_grupo_remote_datasource.dart';
import '../../data/models/estudiante_grupo_model.dart';
import '../helpers/identificadores_pegados.dart';

/// Lista de trabajo de los estudiantes de un grupo antes y después de guardar.
class EstudiantesGrupoState extends Equatable {
  final bool cargando;
  final bool guardando;

  /// Estudiantes ya resueltos por el servidor que siguen en la lista.
  final List<EstudianteGrupo> estudiantes;

  /// Identificadores agregados por el usuario aún sin guardar.
  final List<String> pendientes;

  /// Hay cambios sin enviar (altas o retiros).
  final bool modificado;
  final ResultadoEstudiantesGrupo? resultado;
  final String? error;

  const EstudiantesGrupoState({
    this.cargando = false,
    this.guardando = false,
    this.estudiantes = const [],
    this.pendientes = const [],
    this.modificado = false,
    this.resultado,
    this.error,
  });

  int get total => estudiantes.length + pendientes.length;

  EstudiantesGrupoState copyWith({
    bool? cargando,
    bool? guardando,
    List<EstudianteGrupo>? estudiantes,
    List<String>? pendientes,
    bool? modificado,
    ResultadoEstudiantesGrupo? resultado,
    String? error,
  }) => EstudiantesGrupoState(
    cargando: cargando ?? false,
    guardando: guardando ?? false,
    estudiantes: estudiantes ?? this.estudiantes,
    pendientes: pendientes ?? this.pendientes,
    modificado: modificado ?? this.modificado,
    resultado: resultado,
    error: error,
  );

  @override
  List<Object?> get props => [
    cargando,
    guardando,
    estudiantes,
    pendientes,
    modificado,
    resultado,
    error,
  ];
}

/// Gestiona los estudiantes de un grupo (US-MAR-13): carga, altas por
/// identificador, retiros y reemplazo completo vía PUT.
class EstudiantesGrupoCubit extends Cubit<EstudiantesGrupoState> {
  final EstudiantesGrupoRemoteDataSource _ds;
  final String grupoId;

  EstudiantesGrupoCubit({
    required this.grupoId,
    EstudiantesGrupoRemoteDataSource? dataSource,
  }) : _ds = dataSource ?? EstudiantesGrupoRemoteDataSource(),
       super(const EstudiantesGrupoState());

  Future<void> cargar() async {
    emit(const EstudiantesGrupoState(cargando: true));
    try {
      emit(EstudiantesGrupoState(estudiantes: await _ds.listar(grupoId)));
    } catch (e) {
      emit(EstudiantesGrupoState(error: mensajeDeError(e)));
    }
  }

  /// Agrega los identificadores de [texto]; devuelve cuántos son nuevos.
  int agregar(String texto) {
    final nuevos = separarIdentificadores(texto)
        .where((v) => !state.estudiantes.any((e) => e.coincide(v)))
        .where(
          (v) =>
              !state.pendientes.any((p) => p.toLowerCase() == v.toLowerCase()),
        )
        .toList();
    if (nuevos.isEmpty) return 0;
    emit(
      state.copyWith(
        pendientes: [...state.pendientes, ...nuevos],
        modificado: true,
      ),
    );
    return nuevos.length;
  }

  void quitarEstudiante(String id) => emit(
    state.copyWith(
      estudiantes: state.estudiantes.where((e) => e.id != id).toList(),
      modificado: true,
    ),
  );

  void quitarPendiente(String identificador) => emit(
    state.copyWith(
      pendientes: state.pendientes.where((p) => p != identificador).toList(),
      modificado: true,
    ),
  );

  /// Envía la lista completa resultante; el servidor la reemplaza por esta.
  Future<bool> guardar() async {
    emit(state.copyWith(guardando: true));
    try {
      final r = await _ds.reemplazar(grupoId, [
        ...state.estudiantes.map((e) => e.id),
        ...state.pendientes,
      ]);
      emit(EstudiantesGrupoState(estudiantes: r.estudiantes, resultado: r));
      return true;
    } catch (e) {
      emit(state.copyWith(error: mensajeDeError(e)));
      return false;
    }
  }
}
