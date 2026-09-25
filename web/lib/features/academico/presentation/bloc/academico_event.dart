import 'package:equatable/equatable.dart';

abstract class AcademicoEvent extends Equatable {
  const AcademicoEvent();

  @override
  List<Object?> get props => [];
}

class LoadAcademicoDataEvent extends AcademicoEvent {
  const LoadAcademicoDataEvent();
}

class CreatePeriodoEvent extends AcademicoEvent {
  final String codigo;
  final String nombre;
  final String fechaInicio;
  final String fechaFin;
  final String estado;

  const CreatePeriodoEvent({
    required this.codigo,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
  });

  @override
  List<Object?> get props => [codigo, nombre, fechaInicio, fechaFin, estado];
}

class CreateFacultadEvent extends AcademicoEvent {
  final String codigo;
  final String nombre;
  final String? sedeId;

  const CreateFacultadEvent({
    required this.codigo,
    required this.nombre,
    this.sedeId,
  });

  @override
  List<Object?> get props => [codigo, nombre, sedeId];
}

class DeleteFacultadEvent extends AcademicoEvent {
  final String id;
  const DeleteFacultadEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateProgramaEvent extends AcademicoEvent {
  final String codigo;
  final String nombre;
  final String facultadId;

  const CreateProgramaEvent({
    required this.codigo,
    required this.nombre,
    required this.facultadId,
  });

  @override
  List<Object?> get props => [codigo, nombre, facultadId];
}

class DeleteProgramaEvent extends AcademicoEvent {
  final String id;
  const DeleteProgramaEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateAsignaturaEvent extends AcademicoEvent {
  final String codigo;
  final String nombre;
  final String programaId;
  final int creditos;

  const CreateAsignaturaEvent({
    required this.codigo,
    required this.nombre,
    required this.programaId,
    required this.creditos,
  });

  @override
  List<Object?> get props => [codigo, nombre, programaId, creditos];
}

class DeleteAsignaturaEvent extends AcademicoEvent {
  final String id;
  const DeleteAsignaturaEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateGrupoEvent extends AcademicoEvent {
  final String numero;
  final String asignaturaId;
  final String periodoId;
  final int cupo;

  const CreateGrupoEvent({
    required this.numero,
    required this.asignaturaId,
    required this.periodoId,
    required this.cupo,
  });

  @override
  List<Object?> get props => [numero, asignaturaId, periodoId, cupo];
}

class CreateAsignacionEvent extends AcademicoEvent {
  final Map<String, dynamic> body;
  const CreateAsignacionEvent(this.body);

  @override
  List<Object?> get props => [body];
}

class DeleteAsignacionEvent extends AcademicoEvent {
  final String id;
  const DeleteAsignacionEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateExcepcionEvent extends AcademicoEvent {
  final String nombre;
  final String tipo;
  final String ambito;
  final String fechaInicio;
  final String fechaFin;

  const CreateExcepcionEvent({
    required this.nombre,
    required this.tipo,
    required this.ambito,
    required this.fechaInicio,
    required this.fechaFin,
  });

  @override
  List<Object?> get props => [nombre, tipo, ambito, fechaInicio, fechaFin];
}

class DeleteExcepcionEvent extends AcademicoEvent {
  final String id;
  const DeleteExcepcionEvent(this.id);

  @override
  List<Object?> get props => [id];
}
