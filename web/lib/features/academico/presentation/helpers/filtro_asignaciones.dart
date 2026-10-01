import '../../data/models/academico_models.dart';

const diasSemana = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

String nombreDia(int dia) =>
    dia >= 1 && dia <= 7 ? diasSemana[dia - 1] : 'Día $dia';

/// Fila lista para mostrar: la asignación con nombres en lugar de ids.
class FilaAsignacion {
  final AsignacionModel asignacion;
  final String asignatura;
  final String grupo;

  const FilaAsignacion(this.asignacion, this.asignatura, this.grupo);

  String get docente => asignacion.docenteNombre.isEmpty
      ? 'Por asignar'
      : asignacion.docenteNombre;

  String get aula => asignacion.modalidad == 'VIRTUAL'
      ? 'Virtual'
      : (asignacion.espacioNombre ?? 'Sin aula');
}

/// Filtros de la pantalla de asignaciones. `periodoId` o `dia` nulos = todos.
class FiltroAsignaciones {
  final String? periodoId;
  final int? dia;
  final String texto;

  const FiltroAsignaciones({this.periodoId, this.dia, this.texto = ''});

  FiltroAsignaciones copiar({
    String? Function()? periodoId,
    int? Function()? dia,
    String? texto,
  }) => FiltroAsignaciones(
    periodoId: periodoId == null ? this.periodoId : periodoId(),
    dia: dia == null ? this.dia : dia(),
    texto: texto ?? this.texto,
  );

  bool get activo => periodoId != null || dia != null || texto.isNotEmpty;

  /// Resuelve nombres, filtra y ordena por día y hora de inicio.
  List<FilaAsignacion> aplicar({
    required List<AsignacionModel> asignaciones,
    required List<AsignaturaModel> asignaturas,
    required List<GrupoModel> grupos,
  }) {
    final nombreAsignatura = {for (final a in asignaturas) a.id: a.nombre};
    final numeroGrupo = {for (final g in grupos) g.id: g.numero};
    final busqueda = _normalizar(texto);
    final filas = <FilaAsignacion>[];
    for (final a in asignaciones) {
      if (periodoId != null && a.periodoId != periodoId) continue;
      if (dia != null && a.diaSemana != dia) continue;
      final fila = FilaAsignacion(
        a,
        a.asignaturaNombre.isNotEmpty
            ? a.asignaturaNombre
            : (nombreAsignatura[a.asignaturaId] ?? 'Asignatura'),
        a.grupoNumero.isNotEmpty
            ? a.grupoNumero
            : (numeroGrupo[a.grupoId] ?? '-'),
      );
      if (busqueda.isNotEmpty && !_coincide(fila, busqueda)) continue;
      filas.add(fila);
    }
    filas.sort((x, y) {
      final d = x.asignacion.diaSemana.compareTo(y.asignacion.diaSemana);
      return d != 0
          ? d
          : x.asignacion.horaInicio.compareTo(y.asignacion.horaInicio);
    });
    return filas;
  }

  static bool _coincide(FilaAsignacion f, String busqueda) => _normalizar(
    '${f.asignatura} ${f.asignacion.asignaturaCodigo} grupo ${f.grupo} '
    '${f.docente} ${f.aula}',
  ).contains(busqueda);

  static String _normalizar(String s) {
    const con = 'áéíóúüñ';
    const sin = 'aeiouun';
    var r = s.toLowerCase().trim();
    for (var i = 0; i < con.length; i++) {
      r = r.replaceAll(con[i], sin[i]);
    }
    return r;
  }
}
