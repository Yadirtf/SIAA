import 'academico_models.dart';

/// Datos de una asignación horaria nueva (US-ACA-03) tal como los elige el
/// usuario. El backend deriva `docenteNombre`, `facultadId` y `espacioNombre`
/// a partir de los ids, por lo que no se envían.
class NuevaAsignacion {
  final String periodoId;
  final GrupoModel grupo;
  final String docenteId;
  final String? codocenteId;
  final String? espacioId;
  final String modalidad;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final String zonaHoraria;

  const NuevaAsignacion({
    required this.periodoId,
    required this.grupo,
    required this.docenteId,
    required this.modalidad,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    this.codocenteId,
    this.espacioId,
    this.zonaHoraria = 'America/Bogota',
  });

  bool get esVirtual => modalidad == 'VIRTUAL';

  /// Principal primero; el co-docente solo si es distinto (US-ACA-08).
  List<String> get docenteIds => [
    docenteId,
    if (codocenteId != null &&
        codocenteId!.isNotEmpty &&
        codocenteId != docenteId)
      codocenteId!,
  ];

  Map<String, dynamic> toJson() => {
    'periodoId': periodoId,
    'grupoId': grupo.id,
    'asignaturaId': grupo.asignaturaId,
    'docenteIds': docenteIds,
    if (!esVirtual && espacioId != null) 'espacioId': espacioId,
    'modalidad': modalidad,
    'franja': {
      'diaSemana': diaSemana,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'zonaHoraria': zonaHoraria,
    },
  };
}
