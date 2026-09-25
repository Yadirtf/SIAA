import 'package:equatable/equatable.dart';

class PeriodoModel extends Equatable {
  final String id;
  final String codigo;
  final String nombre;
  final String fechaInicio;
  final String fechaFin;
  final String estado;

  const PeriodoModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
  });

  factory PeriodoModel.fromJson(Map<String, dynamic> json) {
    return PeriodoModel(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      fechaInicio: json['fechaInicio']?.toString() ?? '',
      fechaFin: json['fechaFin']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'PLANEACION',
    );
  }

  @override
  List<Object?> get props => [
    id,
    codigo,
    nombre,
    fechaInicio,
    fechaFin,
    estado,
  ];
}

class FacultadModel extends Equatable {
  final String id;
  final String codigo;
  final String nombre;
  final String? sedeId;

  const FacultadModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.sedeId,
  });

  factory FacultadModel.fromJson(Map<String, dynamic> json) {
    return FacultadModel(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      sedeId: json['sedeId']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, codigo, nombre, sedeId];
}

class ProgramaModel extends Equatable {
  final String id;
  final String codigo;
  final String nombre;
  final String facultadId;

  const ProgramaModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.facultadId,
  });

  factory ProgramaModel.fromJson(Map<String, dynamic> json) {
    return ProgramaModel(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      facultadId: json['facultadId']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, codigo, nombre, facultadId];
}

class AsignaturaModel extends Equatable {
  final String id;
  final String codigo;
  final String nombre;
  final String programaId;
  final int creditos;

  const AsignaturaModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.programaId,
    required this.creditos,
  });

  factory AsignaturaModel.fromJson(Map<String, dynamic> json) {
    return AsignaturaModel(
      id: json['id']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      programaId: json['programaId']?.toString() ?? '',
      creditos: (json['creditos'] as num?)?.toInt() ?? 3,
    );
  }

  @override
  List<Object?> get props => [id, codigo, nombre, programaId, creditos];
}

class GrupoModel extends Equatable {
  final String id;
  final String numero;
  final String asignaturaId;
  final String periodoId;
  final int cupo;

  const GrupoModel({
    required this.id,
    required this.numero,
    required this.asignaturaId,
    required this.periodoId,
    required this.cupo,
  });

  factory GrupoModel.fromJson(Map<String, dynamic> json) {
    return GrupoModel(
      id: json['id']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      asignaturaId: json['asignaturaId']?.toString() ?? '',
      periodoId: json['periodoId']?.toString() ?? '',
      cupo: (json['cupo'] as num?)?.toInt() ?? 30,
    );
  }

  @override
  List<Object?> get props => [id, numero, asignaturaId, periodoId, cupo];
}

class AsignacionModel extends Equatable {
  final String id;
  final String periodoId;
  final String docenteNombre;
  final String grupoId;
  final String asignaturaId;
  final String? espacioId;
  final String? espacioNombre;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final String modalidad;
  final String estado;

  const AsignacionModel({
    required this.id,
    required this.periodoId,
    required this.docenteNombre,
    required this.grupoId,
    required this.asignaturaId,
    this.espacioId,
    this.espacioNombre,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.modalidad,
    required this.estado,
  });

  factory AsignacionModel.fromJson(Map<String, dynamic> json) {
    final franja = json['franja'] as Map<String, dynamic>? ?? {};
    return AsignacionModel(
      id: json['id']?.toString() ?? '',
      periodoId: json['periodoId']?.toString() ?? '',
      docenteNombre: json['docenteNombre']?.toString() ?? '',
      grupoId: json['grupoId']?.toString() ?? '',
      asignaturaId: json['asignaturaId']?.toString() ?? '',
      espacioId: json['espacioId']?.toString(),
      espacioNombre: json['espacioNombre']?.toString(),
      diaSemana: (franja['diaSemana'] as num?)?.toInt() ?? 1,
      horaInicio: franja['horaInicio']?.toString() ?? '',
      horaFin: franja['horaFin']?.toString() ?? '',
      modalidad: json['modalidad']?.toString() ?? 'PRESENCIAL',
      estado: json['estado']?.toString() ?? 'PROPUESTA',
    );
  }

  @override
  List<Object?> get props => [
    id,
    periodoId,
    docenteNombre,
    grupoId,
    asignaturaId,
    espacioId,
    espacioNombre,
    diaSemana,
    horaInicio,
    horaFin,
    modalidad,
    estado,
  ];
}

class ExcepcionModel extends Equatable {
  final String id;
  final String nombre;
  final String tipo;
  final String ambito;
  final String fechaInicio;
  final String fechaFin;

  const ExcepcionModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.ambito,
    required this.fechaInicio,
    required this.fechaFin,
  });

  factory ExcepcionModel.fromJson(Map<String, dynamic> json) {
    return ExcepcionModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'FESTIVO',
      ambito: json['ambito']?.toString() ?? 'GLOBAL',
      fechaInicio: json['fechaInicio']?.toString() ?? '',
      fechaFin: json['fechaFin']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, nombre, tipo, ambito, fechaInicio, fechaFin];
}
