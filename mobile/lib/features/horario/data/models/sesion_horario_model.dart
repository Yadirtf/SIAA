// sesion_horario_model.dart - Sesión de clase para "Mi horario" (US-ACA-01..09, §9.1)
// Solo expone datos legibles (asignatura, grupo, aula, docentes); nunca identificadores.
import 'package:equatable/equatable.dart';

class SesionHorarioModel extends Equatable {
  final String id;
  final String asignaturaCodigo;
  final String asignaturaNombre;
  final String grupoNumero;
  final String espacioCodigo;
  final String espacioNombre;
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final String estado;
  final List<String> docentesNombres;
  final String? motivoCancelacion;

  const SesionHorarioModel({
    required this.id,
    required this.asignaturaNombre,
    this.asignaturaCodigo = '',
    this.grupoNumero = '',
    this.espacioCodigo = '',
    this.espacioNombre = '',
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
    this.docentesNombres = const [],
    this.motivoCancelacion,
  });

  bool get esCancelada => estado.toUpperCase() == 'CANCELADA';
  bool get enCurso => estado.toUpperCase() == 'EN_CURSO';
  bool get esProgramada => estado.toUpperCase() == 'PROGRAMADA';

  /// "Cálculo I" (o el código si el backend no envió el nombre).
  String get titulo {
    if (asignaturaNombre.isNotEmpty) return asignaturaNombre;
    if (asignaturaCodigo.isNotEmpty) return asignaturaCodigo;
    return 'Asignatura sin nombre';
  }

  /// "Grupo 01" o cadena vacía si se desconoce.
  String get grupoEtiqueta => grupoNumero.isEmpty ? '' : 'Grupo $grupoNumero';

  /// "Cálculo I · Grupo 01".
  String get tituloConGrupo =>
      grupoEtiqueta.isEmpty ? titulo : '$titulo · $grupoEtiqueta';

  /// "A-301 · Aula 301", solo el código o solo el nombre.
  String get aulaEtiqueta {
    if (espacioCodigo.isNotEmpty && espacioNombre.isNotEmpty) {
      return espacioCodigo == espacioNombre
          ? espacioCodigo
          : '$espacioCodigo · $espacioNombre';
    }
    if (espacioCodigo.isNotEmpty) return espacioCodigo;
    if (espacioNombre.isNotEmpty) return espacioNombre;
    return 'Aula por confirmar';
  }

  /// Etiqueta legible del estado de la sesión.
  String get estadoEtiqueta {
    switch (estado.toUpperCase()) {
      case 'PROGRAMADA':
        return 'Programada';
      case 'EN_CURSO':
        return 'En curso';
      case 'REALIZADA':
        return 'Realizada';
      case 'CANCELADA':
        return 'Cancelada';
      case 'SIN_DOCENTE':
        return 'Sin docente';
      case 'EXCLUIDA':
        return 'No lectiva';
      default:
        return estado;
    }
  }

  /// Soporta el DTO de GET /sesiones y el resumen de GET /me/sesiones/hoy.
  factory SesionHorarioModel.fromJson(Map<String, dynamic> json) {
    String texto(String clave) => (json[clave] ?? '').toString().trim();

    final inicio = DateTime.tryParse(texto('inicioProgramado'))?.toLocal();
    final fin = DateTime.tryParse(texto('finProgramado'))?.toLocal();
    final fecha = DateTime.tryParse(texto('fecha')) ?? inicio ?? DateTime.now();

    final motivo = texto('motivoCancelacion');
    return SesionHorarioModel(
      id: texto('id').isNotEmpty ? texto('id') : texto('sesionId'),
      asignaturaCodigo: texto('asignaturaCodigo'),
      // /me/sesiones/hoy envía el nombre ya resuelto en "asignatura".
      asignaturaNombre: texto('asignaturaNombre').isNotEmpty
          ? texto('asignaturaNombre')
          : texto('asignatura'),
      grupoNumero: texto('grupoNumero').isNotEmpty
          ? texto('grupoNumero')
          : texto('grupo'),
      espacioCodigo: texto('espacioCodigo'),
      espacioNombre: texto('espacioNombre'),
      fecha: DateTime(fecha.year, fecha.month, fecha.day),
      horaInicio:
          texto('horaInicio').isNotEmpty ? texto('horaInicio') : _hora(inicio),
      horaFin: texto('horaFin').isNotEmpty ? texto('horaFin') : _hora(fin),
      estado: texto('estado').isNotEmpty ? texto('estado') : 'PROGRAMADA',
      docentesNombres: (json['docentesNombres'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      motivoCancelacion: motivo.isEmpty ? null : motivo,
    );
  }

  static String _hora(DateTime? t) => t == null
      ? '--:--'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [
        id,
        asignaturaCodigo,
        asignaturaNombre,
        grupoNumero,
        espacioCodigo,
        espacioNombre,
        fecha,
        horaInicio,
        horaFin,
        estado,
        docentesNombres,
        motivoCancelacion,
      ];
}
