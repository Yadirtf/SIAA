import 'package:equatable/equatable.dart';

class FilaImportacionModel extends Equatable {
  final int numeroFila;
  final String periodoCodigo;
  final String facultadCodigo;
  final String programaCodigo;
  final String asignaturaCodigo;
  final String asignaturaNombre;
  final String grupoCodigo;
  final String docenteDocumento;
  final String aulaCodigo;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final String modalidad;
  final bool valida;
  final List<String> errores;
  final List<String> advertencias;

  const FilaImportacionModel({
    required this.numeroFila,
    required this.periodoCodigo,
    required this.facultadCodigo,
    required this.programaCodigo,
    required this.asignaturaCodigo,
    required this.asignaturaNombre,
    required this.grupoCodigo,
    required this.docenteDocumento,
    required this.aulaCodigo,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.modalidad,
    required this.valida,
    required this.errores,
    this.advertencias = const [],
  });

  factory FilaImportacionModel.fromJson(Map<String, dynamic> json) {
    final errs =
        (json['errores'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return FilaImportacionModel(
      numeroFila: (json['numeroFila'] as num?)?.toInt() ?? 0,
      periodoCodigo: json['periodoCodigo']?.toString() ?? '',
      facultadCodigo: json['facultadCodigo']?.toString() ?? '',
      programaCodigo: json['programaCodigo']?.toString() ?? '',
      asignaturaCodigo: json['asignaturaCodigo']?.toString() ?? '',
      asignaturaNombre: json['asignaturaNombre']?.toString() ?? '',
      grupoCodigo: json['grupoCodigo']?.toString() ?? '',
      docenteDocumento: json['docenteDocumento']?.toString() ?? '',
      aulaCodigo: json['aulaCodigo']?.toString() ?? '',
      diaSemana: (json['diaSemana'] as num?)?.toInt() ?? 1,
      horaInicio: json['horaInicio']?.toString() ?? '08:00',
      horaFin: json['horaFin']?.toString() ?? '10:00',
      modalidad: json['modalidad']?.toString() ?? 'PRESENCIAL',
      valida: json['valida'] as bool? ?? false,
      errores: errs,
      advertencias:
          (json['advertencias'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'numeroFila': numeroFila,
    'periodoCodigo': periodoCodigo,
    'facultadCodigo': facultadCodigo,
    'programaCodigo': programaCodigo,
    'asignaturaCodigo': asignaturaCodigo,
    'asignaturaNombre': asignaturaNombre,
    'grupoCodigo': grupoCodigo,
    'docenteDocumento': docenteDocumento,
    'aulaCodigo': aulaCodigo,
    'diaSemana': diaSemana,
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'modalidad': modalidad,
    'valida': valida,
    'errores': errores,
    'advertencias': advertencias,
  };

  @override
  List<Object?> get props => [
    numeroFila,
    periodoCodigo,
    facultadCodigo,
    programaCodigo,
    asignaturaCodigo,
    grupoCodigo,
    docenteDocumento,
    aulaCodigo,
    diaSemana,
    horaInicio,
    horaFin,
    valida,
    errores,
    advertencias,
  ];
}

class PreviewImportacionModel extends Equatable {
  final int totalFilas;
  final int filasValidas;
  final int filasConError;
  final List<FilaImportacionModel> filas;
  final String formato;
  final double umbralErroresPct;

  /// Si las filas con error superan el umbral, al confirmar no se aplica nada (AC-03).
  final bool superaUmbral;

  const PreviewImportacionModel({
    required this.totalFilas,
    required this.filasValidas,
    required this.filasConError,
    required this.filas,
    this.formato = 'CSV',
    this.umbralErroresPct = 0,
    this.superaUmbral = false,
  });

  factory PreviewImportacionModel.fromJson(Map<String, dynamic> json) {
    final list =
        (json['filas'] as List<dynamic>?)
            ?.map(
              (e) => FilaImportacionModel.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [];

    return PreviewImportacionModel(
      totalFilas: (json['totalFilas'] as num?)?.toInt() ?? 0,
      filasValidas: (json['filasValidas'] as num?)?.toInt() ?? 0,
      filasConError: (json['filasConError'] as num?)?.toInt() ?? 0,
      filas: list,
      formato: json['formato']?.toString() ?? 'CSV',
      umbralErroresPct: (json['umbralErroresPct'] as num?)?.toDouble() ?? 0,
      superaUmbral: json['superaUmbral'] == true,
    );
  }

  @override
  List<Object?> get props => [
    totalFilas,
    filasValidas,
    filasConError,
    filas,
    superaUmbral,
  ];
}

/// Resultado de aplicar la carga: si [aplicada] es falso no se guardó nada.
class ResultadoImportacionModel extends Equatable {
  final bool aplicada;
  final int asignacionesCreadas;
  final int gruposCreados;
  final int filasOmitidas;
  final String mensaje;
  final PreviewImportacionModel? informe;

  const ResultadoImportacionModel({
    required this.aplicada,
    required this.mensaje,
    this.asignacionesCreadas = 0,
    this.gruposCreados = 0,
    this.filasOmitidas = 0,
    this.informe,
  });

  factory ResultadoImportacionModel.fromJson(Map<String, dynamic> json) {
    final informe = json['informe'];
    return ResultadoImportacionModel(
      aplicada: json['aplicada'] == true,
      mensaje: json['mensaje']?.toString() ?? '',
      asignacionesCreadas: (json['asignacionesCreadas'] as num?)?.toInt() ?? 0,
      gruposCreados: (json['gruposCreados'] as num?)?.toInt() ?? 0,
      filasOmitidas: (json['filasOmitidas'] as num?)?.toInt() ?? 0,
      informe: informe is Map<String, dynamic>
          ? PreviewImportacionModel.fromJson(informe)
          : null,
    );
  }

  @override
  List<Object?> get props => [aplicada, asignacionesCreadas, mensaje];
}
