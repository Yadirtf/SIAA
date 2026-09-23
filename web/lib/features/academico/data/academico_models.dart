// Modelos y DTOs para la gestión académica en la consola Web (EP-04).

class PeriodoModel {
  final String id;
  final String codigo;
  final String nombre;
  final String fechaInicio;
  final String fechaFin;
  final String estado; // PLANEACION, ACTIVO, CERRADO
  final String? sedeId;
  final String? codigoExterno;
  final List<String> advertencias;

  const PeriodoModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    this.sedeId,
    this.codigoExterno,
    this.advertencias = const [],
  });

  factory PeriodoModel.fromJson(Map<String, dynamic> json) => PeriodoModel(
        id: json['id'] as String? ?? '',
        codigo: json['codigo'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        fechaInicio: json['fechaInicio'] as String? ?? '',
        fechaFin: json['fechaFin'] as String? ?? '',
        estado: json['estado'] as String? ?? 'PLANEACION',
        sedeId: json['sedeId'] as String?,
        codigoExterno: json['codigoExterno'] as String?,
        advertencias: (json['advertencias'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class FacultadModel {
  final String id;
  final String codigo;
  final String nombre;
  final String? sedeId;
  final String? codigoExterno;

  const FacultadModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.sedeId,
    this.codigoExterno,
  });

  factory FacultadModel.fromJson(Map<String, dynamic> json) => FacultadModel(
        id: json['id'] as String? ?? '',
        codigo: json['codigo'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        sedeId: json['sedeId'] as String?,
        codigoExterno: json['codigoExterno'] as String?,
      );
}

class ProgramaModel {
  final String id;
  final String codigo;
  final String nombre;
  final String facultadId;
  final String? codigoExterno;

  const ProgramaModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.facultadId,
    this.codigoExterno,
  });

  factory ProgramaModel.fromJson(Map<String, dynamic> json) => ProgramaModel(
        id: json['id'] as String? ?? '',
        codigo: json['codigo'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        facultadId: json['facultadId'] as String? ?? '',
        codigoExterno: json['codigoExterno'] as String?,
      );
}

class AsignaturaModel {
  final String id;
  final String codigo;
  final String nombre;
  final String programaId;
  final int creditos;
  final String? codigoExterno;

  const AsignaturaModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.programaId,
    required this.creditos,
    this.codigoExterno,
  });

  factory AsignaturaModel.fromJson(Map<String, dynamic> json) =>
      AsignaturaModel(
        id: json['id'] as String? ?? '',
        codigo: json['codigo'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        programaId: json['programaId'] as String? ?? '',
        creditos: json['creditos'] as int? ?? 3,
        codigoExterno: json['codigoExterno'] as String?,
      );
}

class GrupoModel {
  final String id;
  final String numero;
  final String asignaturaId;
  final String periodoId;
  final int cupo;
  final String? codigoExterno;

  const GrupoModel({
    required this.id,
    required this.numero,
    required this.asignaturaId,
    required this.periodoId,
    required this.cupo,
    this.codigoExterno,
  });

  factory GrupoModel.fromJson(Map<String, dynamic> json) => GrupoModel(
        id: json['id'] as String? ?? '',
        numero: json['numero'] as String? ?? '',
        asignaturaId: json['asignaturaId'] as String? ?? '',
        periodoId: json['periodoId'] as String? ?? '',
        cupo: json['cupo'] as int? ?? 30,
        codigoExterno: json['codigoExterno'] as String?,
      );
}

class FranjaModel {
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final String zonaHoraria;

  const FranjaModel({
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    this.zonaHoraria = 'America/Bogota',
  });

  factory FranjaModel.fromJson(Map<String, dynamic> json) => FranjaModel(
        diaSemana: json['diaSemana'] as int? ?? 1,
        horaInicio: json['horaInicio'] as String? ?? '08:00',
        horaFin: json['horaFin'] as String? ?? '10:00',
        zonaHoraria: json['zonaHoraria'] as String? ?? 'America/Bogota',
      );

  Map<String, dynamic> toJson() => {
        'diaSemana': diaSemana,
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'zonaHoraria': zonaHoraria,
      };

  String get diaNombre {
    switch (diaSemana) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Día $diaSemana';
    }
  }
}

class AsignacionModel {
  final String id;
  final String periodoId;
  final List<String> docenteIds;
  final String docenteNombre;
  final String grupoId;
  final String asignaturaId;
  final String facultadId;
  final String? espacioId;
  final String? espacioNombre;
  final FranjaModel franja;
  final String modalidad; // PRESENCIAL, VIRTUAL, HIBRIDA
  final bool exentaGeoespacial;
  final String estado;
  final String fechaInicio;
  final String fechaFin;
  final List<String> advertencias;

  const AsignacionModel({
    required this.id,
    required this.periodoId,
    required this.docenteIds,
    required this.docenteNombre,
    required this.grupoId,
    required this.asignaturaId,
    required this.facultadId,
    this.espacioId,
    this.espacioNombre,
    required this.franja,
    required this.modalidad,
    required this.exentaGeoespacial,
    required this.estado,
    required this.fechaInicio,
    required this.fechaFin,
    this.advertencias = const [],
  });

  factory AsignacionModel.fromJson(Map<String, dynamic> json) =>
      AsignacionModel(
        id: json['id'] as String? ?? '',
        periodoId: json['periodoId'] as String? ?? '',
        docenteIds: (json['docenteIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        docenteNombre: json['docenteNombre'] as String? ?? '',
        grupoId: json['grupoId'] as String? ?? '',
        asignaturaId: json['asignaturaId'] as String? ?? '',
        facultadId: json['facultadId'] as String? ?? '',
        espacioId: json['espacioId'] as String?,
        espacioNombre: json['espacioNombre'] as String?,
        franja: FranjaModel.fromJson(
            json['franja'] as Map<String, dynamic>? ?? {}),
        modalidad: json['modalidad'] as String? ?? 'PRESENCIAL',
        exentaGeoespacial: json['exentaGeoespacial'] as bool? ?? false,
        estado: json['estado'] as String? ?? 'ACTIVA',
        fechaInicio: json['fechaInicio'] as String? ?? '',
        fechaFin: json['fechaFin'] as String? ?? '',
        advertencias: (json['advertencias'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class ExcepcionModel {
  final String id;
  final String nombre;
  final String tipo; // FESTIVO, RECESO, JORNADA_INSTITUCIONAL, PARO
  final String ambito; // GLOBAL, SEDE, FACULTAD
  final String? ambitoId;
  final String fechaInicio;
  final String fechaFin;

  const ExcepcionModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.ambito,
    this.ambitoId,
    required this.fechaInicio,
    required this.fechaFin,
  });

  factory ExcepcionModel.fromJson(Map<String, dynamic> json) => ExcepcionModel(
        id: json['id'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        tipo: json['tipo'] as String? ?? 'FESTIVO',
        ambito: json['ambito'] as String? ?? 'GLOBAL',
        ambitoId: json['ambitoId'] as String?,
        fechaInicio: json['fechaInicio'] as String? ?? '',
        fechaFin: json['fechaFin'] as String? ?? '',
      );
}
