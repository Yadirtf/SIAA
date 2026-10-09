import 'package:equatable/equatable.dart';

import 'diferencia_parametro.dart';

export 'diferencia_parametro.dart';

class SesionModel extends Equatable {
  final String id;
  final String periodoId;
  final String asignacionId;
  final String asignaturaId;
  final String grupoId;
  final List<String> docenteIds;
  final String espacioId;
  final String fecha;
  final String horaInicio;
  final String horaFin;
  final String inicioProgramado;
  final String finProgramado;
  final String estado;
  final String motivoCancelacion;

  // Nombres legibles que el backend adjunta a cada sesión (GET /sesiones).
  final String asignaturaCodigo;
  final String asignaturaNombre;
  final String grupoNumero;
  final String espacioCodigo;
  final String espacioNombre;
  final List<String> docentesNombres;

  // Ubicación del aula (bloque y sede) para ubicar la clase rápidamente.
  final String sedeId;
  final String sedeNombre;
  final String bloqueId;
  final String bloqueNombre;

  /// Parámetros con que se generó la sesión; no cambian aunque cambie la
  /// cascada (RN-002). Solo vienen completos en GET /sesiones/:id.
  final Map<String, dynamic> parametrosCongelados;

  /// Claves congeladas que difieren del valor vigente (US-PAR-03 AC-03).
  final List<DiferenciaParametro> parametrosDiferentes;

  const SesionModel({
    required this.id,
    required this.periodoId,
    required this.asignacionId,
    required this.asignaturaId,
    required this.grupoId,
    required this.docenteIds,
    required this.espacioId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.inicioProgramado,
    required this.finProgramado,
    required this.estado,
    this.motivoCancelacion = '',
    this.asignaturaCodigo = '',
    this.asignaturaNombre = '',
    this.grupoNumero = '',
    this.espacioCodigo = '',
    this.espacioNombre = '',
    this.docentesNombres = const [],
    this.sedeId = '',
    this.sedeNombre = '',
    this.bloqueId = '',
    this.bloqueNombre = '',
    this.parametrosCongelados = const {},
    this.parametrosDiferentes = const [],
  });

  static String _unir(List<String> partes) =>
      partes.where((p) => p.isNotEmpty).join(' · ');

  /// "A-101 · Aula 101"; "Virtual" sin aula; el id solo si no hay nombre.
  String get aulaTexto {
    if (espacioId.isEmpty) return 'Virtual';
    final nombre = _unir([espacioCodigo, espacioNombre]);
    return nombre.isEmpty ? espacioId : nombre;
  }

  /// "Cálculo I · Grupo 01" (o el id del grupo si no hay nombres).
  String get grupoTexto {
    final asignatura = asignaturaNombre.isNotEmpty
        ? asignaturaNombre
        : asignaturaCodigo;
    final grupo = grupoNumero.isEmpty ? '' : 'Grupo $grupoNumero';
    final texto = _unir([asignatura, grupo]);
    return texto.isEmpty ? grupoId : texto;
  }

  /// Nombres de los docentes en el orden de [docenteIds]; el id solo cuando
  /// falta el nombre de esa posición.
  String get docentesTexto {
    final textos = <String>[
      for (var i = 0; i < docenteIds.length; i++)
        i < docentesNombres.length && docentesNombres[i].trim().isNotEmpty
            ? docentesNombres[i]
            : docenteIds[i],
    ];
    return textos.join(', ');
  }

  /// "Bloque 1 · Sede Central"; vacío para clases virtuales o sin datos.
  String get ubicacionTexto =>
      espacioId.isEmpty ? '' : _unir([bloqueNombre, sedeNombre]);

  /// Nombre de la asignatura, o su código si no hay nombre.
  String get asignaturaTexto => asignaturaNombre.isNotEmpty
      ? asignaturaNombre
      : (asignaturaCodigo.isNotEmpty ? asignaturaCodigo : asignaturaId);

  bool get esCancelada => estado.toUpperCase() == 'CANCELADA';

  factory SesionModel.fromJson(Map<String, dynamic> json) {
    String texto(String clave) => json[clave]?.toString() ?? '';
    final nombres =
        (json['docentesNombres'] as List<dynamic>?)
            ?.map((e) => e?.toString() ?? '')
            .toList() ??
        const <String>[];
    final docs =
        (json['docenteIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return SesionModel(
      id: json['id']?.toString() ?? '',
      periodoId: json['periodoId']?.toString() ?? '',
      asignacionId: json['asignacionId']?.toString() ?? '',
      asignaturaId: json['asignaturaId']?.toString() ?? '',
      grupoId: json['grupoId']?.toString() ?? '',
      docenteIds: docs,
      espacioId: json['espacioId']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      horaInicio: json['horaInicio']?.toString() ?? '',
      horaFin: json['horaFin']?.toString() ?? '',
      inicioProgramado: json['inicioProgramado']?.toString() ?? '',
      finProgramado: json['finProgramado']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'PROGRAMADA',
      motivoCancelacion: json['motivoCancelacion']?.toString() ?? '',
      asignaturaCodigo: texto('asignaturaCodigo'),
      asignaturaNombre: texto('asignaturaNombre'),
      grupoNumero: texto('grupoNumero'),
      espacioCodigo: texto('espacioCodigo'),
      espacioNombre: texto('espacioNombre'),
      docentesNombres: nombres,
      sedeId: texto('sedeId'),
      sedeNombre: texto('sedeNombre'),
      bloqueId: texto('bloqueId'),
      bloqueNombre: texto('bloqueNombre'),
      parametrosCongelados: json['parametrosCongelados'] is Map
          ? Map<String, dynamic>.from(json['parametrosCongelados'] as Map)
          : const {},
      parametrosDiferentes: DiferenciaParametro.listaDesde(
        json['parametrosDiferentes'],
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    periodoId,
    asignacionId,
    asignaturaId,
    grupoId,
    docenteIds,
    espacioId,
    fecha,
    horaInicio,
    horaFin,
    estado,
    motivoCancelacion,
    asignaturaCodigo,
    asignaturaNombre,
    grupoNumero,
    espacioCodigo,
    espacioNombre,
    docentesNombres,
    sedeId,
    sedeNombre,
    bloqueId,
    bloqueNombre,
    parametrosCongelados,
    parametrosDiferentes,
  ];
}
