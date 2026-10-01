import 'package:flutter/material.dart';

import '../../data/models/sesion_model.dart';

/// Columnas por las que se puede ordenar la tabla de sesiones.
enum ColumnaSesion { fecha, asignatura, grupo, docente, aula, estado }

const estadosSesion = {
  'PROGRAMADA': 'Programada',
  'EN_CURSO': 'En curso',
  'REALIZADA': 'Realizada',
  'CANCELADA': 'Cancelada',
  'EXCLUIDA': 'Excluida',
};

String nombreEstadoSesion(String estado) =>
    estadosSesion[estado.toUpperCase()] ?? estado;

/// Filtros que se aplican sobre las sesiones ya cargadas del rango elegido.
/// Un valor nulo significa "todos".
class FiltroSesiones {
  final String? sedeId;
  final String? bloqueId;
  final String? espacioId;
  final String? docenteId;
  final String? estado;
  final String texto;

  const FiltroSesiones({
    this.sedeId,
    this.bloqueId,
    this.espacioId,
    this.docenteId,
    this.estado,
    this.texto = '',
  });

  FiltroSesiones copiar({
    String? Function()? sedeId,
    String? Function()? bloqueId,
    String? Function()? espacioId,
    String? Function()? docenteId,
    String? Function()? estado,
    String? texto,
  }) => FiltroSesiones(
    sedeId: sedeId == null ? this.sedeId : sedeId(),
    bloqueId: bloqueId == null ? this.bloqueId : bloqueId(),
    espacioId: espacioId == null ? this.espacioId : espacioId(),
    docenteId: docenteId == null ? this.docenteId : docenteId(),
    estado: estado == null ? this.estado : estado(),
    texto: texto ?? this.texto,
  );

  bool get activo =>
      sedeId != null ||
      bloqueId != null ||
      espacioId != null ||
      docenteId != null ||
      estado != null ||
      texto.trim().isNotEmpty;

  bool _coincide(SesionModel s) {
    if (sedeId != null && s.sedeId != sedeId) return false;
    if (bloqueId != null && s.bloqueId != bloqueId) return false;
    if (espacioId != null && s.espacioId != espacioId) return false;
    if (docenteId != null && !s.docenteIds.contains(docenteId)) return false;
    if (estado != null && s.estado.toUpperCase() != estado) return false;
    final q = sinTildes(texto.trim());
    if (q.isEmpty) return true;
    return sinTildes(
      [
        s.asignaturaTexto,
        s.asignaturaCodigo,
        s.grupoNumero,
        s.docentesTexto,
        s.aulaTexto,
        s.ubicacionTexto,
      ].join(' '),
    ).contains(q);
  }

  List<SesionModel> aplicar(List<SesionModel> sesiones) =>
      sesiones.where(_coincide).toList();
}

/// Minúsculas y sin tildes, para buscar "calculo" y encontrar "Cálculo".
String sinTildes(String texto) {
  const de = 'áéíóúüñ';
  const a = 'aeiouun';
  final buf = StringBuffer();
  for (final c in texto.toLowerCase().split('')) {
    final i = de.indexOf(c);
    buf.write(i < 0 ? c : a[i]);
  }
  return buf.toString();
}

/// Ordena una copia de [sesiones]; fecha y hora van juntas.
List<SesionModel> ordenarSesiones(
  List<SesionModel> sesiones,
  ColumnaSesion columna,
  bool ascendente,
) {
  String clave(SesionModel s) => switch (columna) {
    ColumnaSesion.fecha => '${s.fecha} ${s.horaInicio}',
    ColumnaSesion.asignatura => sinTildes(s.asignaturaTexto),
    ColumnaSesion.grupo => s.grupoNumero,
    ColumnaSesion.docente => sinTildes(s.docentesTexto),
    ColumnaSesion.aula => sinTildes(s.aulaTexto),
    ColumnaSesion.estado => s.estado,
  };
  final copia = [...sesiones];
  copia.sort((a, b) {
    final c = clave(a).compareTo(clave(b));
    final r = c != 0
        ? c
        : '${a.fecha} ${a.horaInicio}'.compareTo('${b.fecha} ${b.horaInicio}');
    return ascendente ? r : -r;
  });
  return copia;
}

/// Opciones de los filtros (id → nombre) tomadas de las sesiones cargadas, así
/// solo se ofrece lo que existe en el rango. Bloques y aulas se acotan a la
/// sede y bloque elegidos.
class OpcionesSesiones {
  final Map<String, String> sedes;
  final Map<String, String> bloques;
  final Map<String, String> aulas;
  final Map<String, String> docentes;

  const OpcionesSesiones(this.sedes, this.bloques, this.aulas, this.docentes);

  factory OpcionesSesiones.desde(List<SesionModel> sesiones, FiltroSesiones f) {
    final sedes = <String, String>{};
    final bloques = <String, String>{};
    final aulas = <String, String>{};
    final docentes = <String, String>{};
    for (final s in sesiones) {
      if (s.sedeId.isNotEmpty) {
        sedes[s.sedeId] = s.sedeNombre.isEmpty
            ? 'Sede sin nombre'
            : s.sedeNombre;
      }
      final enSede = f.sedeId == null || s.sedeId == f.sedeId;
      if (enSede && s.bloqueId.isNotEmpty) {
        bloques[s.bloqueId] = s.bloqueNombre.isEmpty
            ? 'Bloque sin nombre'
            : s.bloqueNombre;
      }
      final enBloque = f.bloqueId == null || s.bloqueId == f.bloqueId;
      if (enSede && enBloque && s.espacioId.isNotEmpty) {
        aulas[s.espacioId] = s.aulaTexto;
      }
      for (var i = 0; i < s.docenteIds.length; i++) {
        final nombre = i < s.docentesNombres.length ? s.docentesNombres[i] : '';
        docentes[s.docenteIds[i]] = nombre.trim().isEmpty
            ? s.docenteIds[i]
            : nombre;
      }
    }
    return OpcionesSesiones(
      _ordenado(sedes),
      _ordenado(bloques),
      _ordenado(aulas),
      _ordenado(docentes),
    );
  }

  static Map<String, String> _ordenado(Map<String, String> m) =>
      Map.fromEntries(
        m.entries.toList()
          ..sort((a, b) => sinTildes(a.value).compareTo(sinTildes(b.value))),
      );
}

/// Semana de lunes a domingo que contiene [dia].
DateTimeRange semanaDe(DateTime dia) {
  final d = DateTime(dia.year, dia.month, dia.day);
  final lunes = d.subtract(Duration(days: d.weekday - 1));
  return DateTimeRange(start: lunes, end: lunes.add(const Duration(days: 6)));
}

/// AAAA-MM-DD, el formato que espera el backend.
String fechaIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// "29 sep 2026".
String fechaLegible(DateTime d) => '${d.day} ${_meses[d.month - 1]} ${d.year}';

/// "jue 1 oct" a partir de "2026-10-01"; el texto original si no es fecha.
String fechaSesion(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${_dias[d.weekday - 1]} ${d.day} ${_meses[d.month - 1]}';
}
