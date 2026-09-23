import 'package:equatable/equatable.dart';
import '../../data/models/academico_models.dart';

abstract class AcademicoState extends Equatable {
  const AcademicoState();

  @override
  List<Object?> get props => [];
}

class AcademicoInitial extends AcademicoState {
  const AcademicoInitial();
}

class AcademicoLoading extends AcademicoState {
  const AcademicoLoading();
}

class AcademicoLoaded extends AcademicoState {
  final List<PeriodoModel> periodos;
  final List<FacultadModel> facultades;
  final List<ProgramaModel> programas;
  final List<AsignaturaModel> asignaturas;
  final List<GrupoModel> grupos;
  final List<AsignacionModel> asignaciones;
  final List<ExcepcionModel> excepciones;

  const AcademicoLoaded({
    required this.periodos,
    required this.facultades,
    required this.programas,
    required this.asignaturas,
    required this.grupos,
    required this.asignaciones,
    required this.excepciones,
  });

  @override
  List<Object?> get props => [
        periodos,
        facultades,
        programas,
        asignaturas,
        grupos,
        asignaciones,
        excepciones,
      ];
}

class AcademicoError extends AcademicoState {
  final String message;

  const AcademicoError(this.message);

  @override
  List<Object?> get props => [message];
}
